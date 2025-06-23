import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class APIHelper {
    static let shared = APIHelper()
    
    private init() {}
    
    // MARK: - Регистрация
    func register(name: String, email: String, password: String) async throws -> User {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()

        return authResult.user
    }
    
    // MARK: - Вход
    func login(email: String, password: String) async throws -> User {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
//        guard let user = authResult.user else {
//            throw NSError(domain: "No user signed in", code: 0)
//        }
        return authResult.user
    }
    
    func updateTrackerCurrentValue(trackerId: String, newValue: Double, completion: ((Error?) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]))
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let diaryRef = userRef.collection("FoodDiary").document(today)
        
        diaryRef.getDocument { snapshot, error in
            if let error = error {
                completion?(error)
                return
            }

            guard var data = snapshot?.data(),
                  var trackers = data["trackers"] as? [[String: Any]] else {
                completion?(NSError(domain: "DataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No trackers found"]))
                return
            }

            // Найти и обновить нужный трекер по id
            if let index = trackers.firstIndex(where: { $0["id"] as? String == trackerId }) {
                trackers[index]["currentValue"] = newValue
            }

            // Сохраняем обновлённый массив трекеров
            diaryRef.updateData(["trackers": trackers]) { error in
                if let error = error {
                    print("Ошибка при обновлении трекера: \(error.localizedDescription)")
                }
                completion?(error)
            }
        }
    }

    func updateStepsInFoodDiart(steps: Int, completion: ((Error?) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]))
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        // Получаем сегодняшнюю дату в формате "yyyy-MM-dd"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let diaryRef = userRef.collection("FoodDiary").document(today)
        let burned = Int(caloriesBurned(steps: steps, weightKg: UserManager.shared.getUserProfile()?.weight ?? 70))
        // Обновляем поле steps.current
        diaryRef.updateData([
            "burnedCalories": burned,
            "steps.current": steps
        ]) { error in
            completion?(error)
        }
    }
    
    func caloriesBurned(steps: Int, weightKg: Double) -> Double {
        // Среднее количество калорий, сжигаемых на 1 шаг (примерно 0.04-0.06 ккал для веса 70 кг)
        let caloriesPerStep = 0.0005 * weightKg
        return Double(steps) * caloriesPerStep
    }
    
    func updateCurrentWeight(_ newWeight: Double, completion: ((Error?) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]))
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        // Получаем сегодняшнюю дату в нужном формате (yyyy-MM-dd)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let diaryRef = userRef.collection("FoodDiary").document(today)

        // Обновляем currentWeight и вес в foodDiary
        userRef.updateData([
            "currentWeight": newWeight
        ]) { error in
            if let error = error {
                print("Ошибка при обновлении веса: \(error)")
            }
            completion?(error)
        }
        
        diaryRef.setData(["currentWeight": newWeight], merge: true) { error in
            if let error = error {
                print("Ошибка при обновлении дневника: \(error)")
            }
            completion?(error)
        }
    }
    
    func finishOnbooarding(for userProfile: UserProfile?) async throws {
        guard let userProfile, let goal = userProfile.currentGoal else {
            return
        }

        try await saveProfile(with: userProfile)
        
        UserManager.shared.save(userProfile: userProfile)
        
        let diary = FoodDiary.generatePlan(weight: userProfile.weight, targetWeight: userProfile.targetWeight, goal: goal.mapToWeightGoal())
        
        FirestoreManager.shared.createTodayFoodDiary(userId: userProfile.id, foodDiary: diary)
    }
    
    func fetchFoodDiary() async throws -> FoodDiary? {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let docRef = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("FoodDiary")
            .document(today)
        
        let snapshot = try await docRef.getDocument()
        
        if let data = snapshot.data() {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let diary = try JSONDecoder().decode(FoodDiary.self, from: jsonData)
            return diary
        }
        return nil
    }
    
    func fetchUserProfile(for userId: String) async throws -> UserProfile {
        let userProfile: UserProfile = try await FirestoreManager.shared.fetchData(fromCollection: "users", documentId: userId)

        print("User Profile: \(userProfile)")
        return userProfile
    }
    
    func addMeal(for type: MealType, and food: FoodItem) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let docRef = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("FoodDiary")
            .document(today)

        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }

            guard
                var meals = data["meals"] as? [[String: Any]],
                var eatenCalories = data["eatenCalories"] as? Int,
                var remainingCalories = data["remainingCalories"] as? Int,
                var nutrition = data["nutrition"] as? [[String: Any]]
            else { return }

            // Обновляем калории в meals
            guard let mealIndex = meals.firstIndex(where: { $0["name"] as? String == type.rawValue.lowercased() }) else {
                return
            }

            if let currentCalories = meals[mealIndex]["calories"] as? Int {
                meals[mealIndex]["calories"] = currentCalories + food.calories
                eatenCalories += food.calories
                remainingCalories -= food.calories
            }

            // Обновляем нутриенты
            let nutrientsToUpdate: [(name: String, amount: Int)] = [
                ("Carbs", food.nutrition.carbs),
                ("Protein", food.nutrition.protein),
                ("Fat", food.nutrition.fats)
            ]

            for (name, amount) in nutrientsToUpdate {
                if let index = nutrition.firstIndex(where: { $0["name"] as? String == name }),
                   let current = nutrition[index]["current"] as? Int {
                    nutrition[index]["current"] = current + amount
                }
            }

            Task {
                do {
                    try await self.updateMealsAsync(
                        docRef: docRef,
                        meals: meals,
                        remainingCalories: remainingCalories,
                        eatenCalories: eatenCalories,
                        nutrition: nutrition
                    )
                    NotificationCenter.default.post(name: .shouldFetchHomeData, object: nil)
                } catch {
                    print("Ошибка обновления: \(error)")
                }
            }
        }
    }
    
//    func googleLogin(completion: Callback) {
//        GIDSignIn.sharedInstance.signIn(
//            withPresenting: (UIApplication.shared.windows.first?.rootViewController)!) { signInResult, error in
//                guard let result = signInResult else { return }
//                guard let idToken = result.user.idToken?.tokenString else { return }
//
//                let accessToken = result.user.accessToken.tokenString
//                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
//                                                               accessToken: accessToken)
//
//                Auth.auth().signIn(with: credential) { authResult, error in
//                    guard let authResult = authResult else {
//                        print("Error signing in: \(error?.localizedDescription ?? "Unknown error")")
//                        return
//                    }
//
//                    let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
//
//                    if isNewUser {
//                        if let email = result.user.profile?.email,
//                           let username = email.components(separatedBy: "@").first {
//                            print(email)
//                        }
//                        
//                    } else {
//                        print("Это логин")
//                    }
//                }
//            }
//    }
    
//    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> URL {
//        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
//        
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data"])
//        }
//        
//        let metadata = StorageMetadata()
//        metadata.contentType = "image/jpeg"
//        
//        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
//        
//        let downloadURL = try await storageRef.downloadURL()
//        return downloadURL
//    }
    
    func addTrackersToTodayDiary(trackers: [TrackerData]) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let diaryRef = db.collection("users")
            .document(userId)
            .collection("FoodDiary")
            .document(today)

        // Для каждого трекера — добавить через arrayUnion
        for tracker in trackers {
            do {
                let encodedTracker = try Firestore.Encoder().encode(tracker)

                diaryRef.updateData([
                    "trackers": FieldValue.arrayUnion([encodedTracker])
                ]) { error in
                    if let error = error {
                        print("Error adding tracker: \(error)")
                    } else {
                        print("Tracker added successfully.")
                    }
                }
            } catch {
                print("Encoding error: \(error)")
            }
        }
    }
    
    func updateMealsAsync(docRef: DocumentReference, meals: [[String : Any]], remainingCalories: Int, eatenCalories: Int, nutrition: [[String : Any]]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            docRef.updateData(["meals": meals, "remainingCalories": remainingCalories, "eatenCalories": eatenCalories, "nutrition": nutrition]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func saveProfile(with profile: UserProfile) async throws {
        try await Firestore.firestore().save(profile, toCollection: "users", withDocumentId: profile.id)
    }
    
    func updateUserProfileFields(userId: String, fieldsToUpdate: [String: Any]) async throws {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userId)
        
        try await docRef.updateData(fieldsToUpdate)
    }
    
    // MARK: - Выход
    func logout(completion: @escaping Callback) {
        Task {
            do {
                try Auth.auth().signOut()
                UserManager.shared.logout()
                await MainActor.run {
                    completion()
                }
            } catch {
                print(error)
            }
        }
    }
    
    func createFoodDiary() {
    }
    
    // MARK: - Отправить письмо для подтверждения Email
    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "No user logged in", code: 0)
        }
        try await user.sendEmailVerification()
    }
    
    // MARK: - Проверить верификацию Email
    func checkEmailVerification() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "No user logged in", code: 0)
        }
        try await user.reload()
        return user.isEmailVerified
    }
    
    // MARK: - Изменить пароль
    func changePassword(newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "No user logged in", code: 0)
        }
        try await user.updatePassword(to: newPassword)
    }
    
    // MARK: - Получить UID текущего пользователя
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func toggleFavorite(for recipeId: String, isFavorite: Bool) async throws {
        let db = Firestore.firestore()
        let docRef = db.collection("recipesDemo").document(recipeId)

        try await docRef.updateData([
            "isFavorite": isFavorite
        ])
    }

    func toggleShoppingList(for recipeId: String, toDelete: Bool = false) async throws {
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser?.uid ?? "defaultUser"
        let docRef = db.collection("users").document(userId)
        
        // Добавить recipeId в массив shoppingList, если его ещё нет
        if toDelete {
            try await docRef.updateData([
                "shoppingList": FieldValue.arrayRemove([recipeId])
            ])
        } else {
            try await docRef.updateData([
                "shoppingList": FieldValue.arrayUnion([recipeId])
            ])
        }
    }
    
    func fetchProfile() async throws -> UserProfile {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .getDocument()

        guard let data = snapshot.data() else {
            throw NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }

        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        let profile = try JSONDecoder().decode(UserProfile.self, from: jsonData)
        
        UserManager.shared.save(userProfile: profile)
        
        return profile
    }
    
    func fetchShoppingListIDs() async throws -> [String] {
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser?.uid ?? "defaultUser"
        let docRef = db.collection("users").document(userId)
        
        let snapshot = try await docRef.getDocument()
        
        if let data = snapshot.data(),
           let shoppingList = data["shoppingList"] as? [String] {
            return shoppingList
        } else {
            return []
        }
    }

    func fetchRecipes() async throws -> [FoodItem] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("recipesDemo").getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()

            guard
                let name = data["name"] as? String,
                let category = data["category"] as? String,
                let url = data["imageName"] as? String,
                let cookTime = data["cookTime"] as? Int,
                let nutrition = data["nutrition"] as? [String: Any],
                let carbs = nutrition["carbs"] as? Int,
                let fats = nutrition["fats"] as? Int,
                let protein = nutrition["protein"] as? Int,
                let isFavourite = data["isFavorite"] as? Bool,
                let calories = data["calories"] as? Int,
                let detail = data["detail"] as? String
            else {
                return FoodItem(id: doc.documentID, name: "name", calories: 10, detail: "ASd", nutrition: NutritionInfo(protein: 10, carbs: 10, fats: 10), imageName: "url", cookTime: 10, isFavorite: false, ingredients: nil, instructions: nil, category: "category")
            }

            let nutritionInfo = NutritionInfo(protein: protein, carbs: carbs, fats: fats)
            
            let instructions = data["instructions"] as? [String]
            let ingredients = data["ingredients"] as? [String]

            return FoodItem(id: doc.documentID, name: name, calories: calories, detail: detail, nutrition: nutritionInfo, imageName: url, cookTime: cookTime, isFavorite: isFavourite, ingredients: ingredients, instructions: instructions, category: category)
        }
    }
    
    func generateSampleMeals() -> [FoodItem] {
        var meals: [FoodItem] = []
        
        // BREAKFAST MEALS (7)
        let breakfastMeals = [
            FoodItem(
                id: "breakfast_1",
                name: "Scrambled Eggs with Toast",
                calories: 350,
                detail: "Fluffy scrambled eggs served with buttered whole grain toast",
                nutrition: NutritionInfo(protein: 18, carbs: 25, fats: 22),
                imageName: "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400",
                cookTime: 10,
                isFavorite: false,
                ingredients: ["3 eggs", "2 slices whole grain bread", "2 tbsp butter", "salt", "pepper", "milk"],
                instructions: ["Beat eggs with milk", "Heat butter in pan", "Add eggs and scramble gently", "Toast bread and butter", "Serve hot"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_2",
                name: "Oatmeal with Berries",
                calories: 280,
                detail: "Creamy oatmeal topped with fresh mixed berries and honey",
                nutrition: NutritionInfo(protein: 8, carbs: 52, fats: 6),
                imageName: "https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=400",
                cookTime: 8,
                isFavorite: true,
                ingredients: ["1 cup rolled oats", "2 cups milk", "1/2 cup mixed berries", "2 tbsp honey", "pinch of salt"],
                instructions: ["Boil milk in saucepan", "Add oats and salt", "Cook for 5 minutes stirring", "Top with berries and honey", "Serve warm"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_3",
                name: "Greek Yogurt Parfait",
                calories: 220,
                detail: "Layered Greek yogurt with granola and fresh fruits",
                nutrition: NutritionInfo(protein: 15, carbs: 28, fats: 8),
                imageName: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400",
                cookTime: 5,
                isFavorite: true,
                ingredients: ["1 cup Greek yogurt", "1/4 cup granola", "1/2 banana sliced", "1/4 cup blueberries", "1 tbsp honey"],
                instructions: ["Layer yogurt in glass", "Add granola layer", "Add fruit layer", "Repeat layers", "Drizzle with honey"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_4",
                name: "Avocado Toast",
                calories: 320,
                detail: "Smashed avocado on sourdough with tomato and seasoning",
                nutrition: NutritionInfo(protein: 9, carbs: 32, fats: 18),
                imageName: "https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400",
                cookTime: 7,
                isFavorite: false,
                ingredients: ["2 slices sourdough bread", "1 ripe avocado", "1 small tomato", "salt", "pepper", "lemon juice"],
                instructions: ["Toast bread until golden", "Mash avocado with lemon", "Spread on toast", "Top with tomato slices", "Season with salt and pepper"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_5",
                name: "Pancakes with Syrup",
                calories: 450,
                detail: "Fluffy buttermilk pancakes with maple syrup and butter",
                nutrition: NutritionInfo(protein: 12, carbs: 68, fats: 16),
                imageName: "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400",
                cookTime: 20,
                isFavorite: true,
                ingredients: ["2 cups flour", "2 eggs", "1.5 cups buttermilk", "2 tbsp sugar", "1 tsp baking powder", "maple syrup"],
                instructions: ["Mix dry ingredients", "Whisk wet ingredients separately", "Combine mixtures gently", "Cook on griddle", "Serve with syrup"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_6",
                name: "Smoothie Bowl",
                calories: 290,
                detail: "Thick fruit smoothie topped with nuts, seeds, and coconut",
                nutrition: NutritionInfo(protein: 10, carbs: 45, fats: 12),
                imageName: "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=400",
                cookTime: 10,
                isFavorite: true,
                ingredients: ["1 frozen banana", "1/2 cup frozen berries", "1/2 cup almond milk", "2 tbsp granola", "1 tbsp chia seeds", "coconut flakes"],
                instructions: ["Blend frozen fruits with milk", "Pour into bowl", "Top with granola", "Sprinkle chia seeds", "Add coconut flakes"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_7",
                name: "French Toast",
                calories: 380,
                detail: "Golden French toast with cinnamon and powdered sugar",
                nutrition: NutritionInfo(protein: 14, carbs: 48, fats: 16),
                imageName: "https://images.unsplash.com/photo-1506084868230-bb9d95c24759?w=400",
                cookTime: 15,
                isFavorite: false,
                ingredients: ["4 slices brioche bread", "3 eggs", "1/2 cup milk", "1 tsp cinnamon", "2 tbsp butter", "powdered sugar"],
                instructions: ["Whisk eggs, milk, cinnamon", "Dip bread in mixture", "Cook in buttered pan", "Flip when golden", "Dust with powdered sugar"],
                category: "Breakfast"
            )
        ]
        
        // LUNCH MEALS (7)
        let lunchMeals = [
            FoodItem(
                id: "lunch_1",
                name: "Caesar Salad",
                calories: 420,
                detail: "Crisp romaine lettuce with parmesan, croutons, and Caesar dressing",
                nutrition: NutritionInfo(protein: 16, carbs: 18, fats: 32),
                imageName: "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["4 cups romaine lettuce", "1/2 cup parmesan cheese", "1 cup croutons", "Caesar dressing", "grilled chicken breast"],
                instructions: ["Chop romaine lettuce", "Add croutons and cheese", "Toss with dressing", "Top with chicken", "Serve immediately"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_2",
                name: "Grilled Chicken Sandwich",
                calories: 480,
                detail: "Grilled chicken breast with lettuce, tomato on ciabatta",
                nutrition: NutritionInfo(protein: 35, carbs: 42, fats: 18),
                imageName: "https://images.unsplash.com/photo-1553979459-d2229ba7433a?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["1 chicken breast", "ciabatta roll", "lettuce", "tomato", "mayo", "salt", "pepper"],
                instructions: ["Season and grill chicken", "Toast ciabatta roll", "Spread mayo on bread", "Layer lettuce and tomato", "Add chicken and serve"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_3",
                name: "Quinoa Bowl",
                calories: 390,
                detail: "Nutritious quinoa bowl with roasted vegetables and tahini",
                nutrition: NutritionInfo(protein: 14, carbs: 52, fats: 14),
                imageName: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
                cookTime: 30,
                isFavorite: true,
                ingredients: ["1 cup quinoa", "mixed vegetables", "chickpeas", "tahini sauce", "olive oil", "lemon juice"],
                instructions: ["Cook quinoa according to package", "Roast vegetables with oil", "Prepare tahini sauce", "Combine in bowl", "Drizzle with sauce"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_4",
                name: "Turkey Club Sandwich",
                calories: 520,
                detail: "Triple-decker sandwich with turkey, bacon, lettuce, and tomato",
                nutrition: NutritionInfo(protein: 28, carbs: 38, fats: 28),
                imageName: "https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400",
                cookTime: 12,
                isFavorite: false,
                ingredients: ["3 slices white bread", "6 oz sliced turkey", "4 strips bacon", "lettuce", "2 tomato slices", "mayo"],
                instructions: ["Toast bread slices", "Cook bacon until crispy", "Spread mayo on toast", "Layer turkey and bacon", "Add lettuce and tomato"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_5",
                name: "Pasta Primavera",
                calories: 450,
                detail: "Fresh pasta with seasonal vegetables in light cream sauce",
                nutrition: NutritionInfo(protein: 16, carbs: 58, fats: 18),
                imageName: "https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["12 oz penne pasta", "mixed vegetables", "heavy cream", "parmesan cheese", "garlic", "olive oil"],
                instructions: ["Cook pasta al dente", "Sauté vegetables with garlic", "Add cream to vegetables", "Toss with pasta", "Top with parmesan"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_6",
                name: "Fish Tacos",
                calories: 380,
                detail: "Grilled fish tacos with cabbage slaw and lime crema",
                nutrition: NutritionInfo(protein: 24, carbs: 36, fats: 16),
                imageName: "https://images.unsplash.com/photo-1565299585323-38174c8c3a08?w=400",
                cookTime: 18,
                isFavorite: true,
                ingredients: ["white fish fillets", "corn tortillas", "cabbage", "lime", "sour cream", "cilantro", "cumin"],
                instructions: ["Season and grill fish", "Make cabbage slaw", "Prepare lime crema", "Warm tortillas", "Assemble tacos with toppings"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_7",
                name: "Mushroom Risotto",
                calories: 420,
                detail: "Creamy Arborio rice with wild mushrooms and parmesan",
                nutrition: NutritionInfo(protein: 12, carbs: 54, fats: 16),
                imageName: "https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=400",
                cookTime: 35,
                isFavorite: false,
                ingredients: ["1.5 cups Arborio rice", "mixed mushrooms", "vegetable broth", "white wine", "parmesan", "onion", "butter"],
                instructions: ["Sauté mushrooms and set aside", "Cook onion until soft", "Add rice and toast briefly", "Add wine and broth gradually", "Stir in mushrooms and cheese"],
                category: "Lunch"
            )
        ]
        
        // DINNER MEALS (7)
        let dinnerMeals = [
            FoodItem(
                id: "dinner_1",
                name: "Grilled Salmon",
                calories: 520,
                detail: "Atlantic salmon with roasted vegetables and quinoa",
                nutrition: NutritionInfo(protein: 42, carbs: 28, fats: 26),
                imageName: "https://images.unsplash.com/photo-1467003909186-9cc02d5de3c8?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["6 oz salmon fillet", "asparagus", "quinoa", "lemon", "olive oil", "garlic", "herbs"],
                instructions: ["Season salmon with herbs", "Roast vegetables with olive oil", "Cook quinoa", "Grill salmon 4-5 min per side", "Serve with lemon"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_2",
                name: "Beef Stir Fry",
                calories: 460,
                detail: "Tender beef strips with mixed vegetables in savory sauce",
                nutrition: NutritionInfo(protein: 32, carbs: 38, fats: 20),
                imageName: "https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["8 oz beef sirloin", "mixed vegetables", "soy sauce", "ginger", "garlic", "rice", "sesame oil"],
                instructions: ["Slice beef thinly", "Stir fry beef until browned", "Add vegetables and cook", "Mix in sauce", "Serve over rice"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_3",
                name: "Chicken Parmesan",
                calories: 580,
                detail: "Breaded chicken breast with marinara and mozzarella",
                nutrition: NutritionInfo(protein: 45, carbs: 42, fats: 24),
                imageName: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400",
                cookTime: 40,
                isFavorite: true,
                ingredients: ["chicken breast", "breadcrumbs", "mozzarella cheese", "marinara sauce", "parmesan", "pasta"],
                instructions: ["Bread and fry chicken", "Top with marinara and cheese", "Bake until cheese melts", "Cook pasta", "Serve together"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_4",
                name: "Vegetable Curry",
                calories: 380,
                detail: "Aromatic mixed vegetable curry with coconut milk and rice",
                nutrition: NutritionInfo(protein: 12, carbs: 58, fats: 14),
                imageName: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400",
                cookTime: 30,
                isFavorite: true,
                ingredients: ["mixed vegetables", "coconut milk", "curry powder", "onion", "garlic", "ginger", "basmati rice"],
                instructions: ["Sauté onion, garlic, ginger", "Add curry powder and vegetables", "Pour in coconut milk", "Simmer until tender", "Serve with rice"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_5",
                name: "Pork Tenderloin",
                calories: 490,
                detail: "Herb-crusted pork tenderloin with roasted potatoes",
                nutrition: NutritionInfo(protein: 38, carbs: 32, fats: 22),
                imageName: "https://images.unsplash.com/photo-1544025162-d76694265947?w=400",
                cookTime: 45,
                isFavorite: false,
                ingredients: ["pork tenderloin", "baby potatoes", "rosemary", "thyme", "garlic", "olive oil", "salt", "pepper"],
                instructions: ["Season pork with herbs", "Roast potatoes with oil", "Sear pork in pan", "Transfer to oven", "Rest before slicing"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_6",
                name: "Shrimp Scampi",
                calories: 420,
                detail: "Garlic shrimp in white wine sauce over linguine",
                nutrition: NutritionInfo(protein: 28, carbs: 48, fats: 12),
                imageName: "https://images.unsplash.com/photo-1563379091339-03246963d7d3?w=400",
                cookTime: 18,
                isFavorite: true,
                ingredients: ["large shrimp", "linguine pasta", "garlic", "white wine", "butter", "parsley", "lemon"],
                instructions: ["Cook pasta al dente", "Sauté garlic in butter", "Add shrimp and wine", "Toss with pasta", "Garnish with parsley"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_7",
                name: "Stuffed Bell Peppers",
                calories: 350,
                detail: "Bell peppers stuffed with ground turkey, rice, and vegetables",
                nutrition: NutritionInfo(protein: 24, carbs: 36, fats: 12),
                imageName: "https://images.unsplash.com/photo-1606728035253-49e8a23146de?w=400",
                cookTime: 50,
                isFavorite: false,
                ingredients: ["bell peppers", "ground turkey", "rice", "onion", "tomato sauce", "cheese", "herbs"],
                instructions: ["Hollow out peppers", "Cook turkey with onion", "Mix with rice and sauce", "Stuff peppers", "Bake until tender"],
                category: "Dinner"
            )
        ]
        
        // SNACK MEALS (7)
        let snackMeals = [
            FoodItem(
                id: "snack_1",
                name: "Mixed Nuts",
                calories: 180,
                detail: "Assorted roasted nuts with sea salt",
                nutrition: NutritionInfo(protein: 6, carbs: 8, fats: 16),
                imageName: "https://images.unsplash.com/photo-1599599810694-57a2ca21cd05?w=400",
                cookTime: 0,
                isFavorite: false,
                ingredients: ["almonds", "walnuts", "cashews", "sea salt"],
                instructions: ["Mix nuts together", "Serve in small portion"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_2",
                name: "Apple with Peanut Butter",
                calories: 210,
                detail: "Fresh apple slices with natural peanut butter",
                nutrition: NutritionInfo(protein: 8, carbs: 24, fats: 12),
                imageName: "https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=400",
                cookTime: 2,
                isFavorite: true,
                ingredients: ["1 medium apple", "2 tbsp peanut butter"],
                instructions: ["Wash and slice apple", "Serve with peanut butter for dipping"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_3",
                name: "Greek Yogurt with Honey",
                calories: 150,
                detail: "Creamy Greek yogurt drizzled with organic honey",
                nutrition: NutritionInfo(protein: 15, carbs: 18, fats: 4),
                imageName: "https://images.unsplash.com/photo-1571212515416-01b8b379d816?w=400",
                cookTime: 1,
                isFavorite: true,
                ingredients: ["1 cup Greek yogurt", "2 tbsp honey"],
                instructions: ["Scoop yogurt into bowl", "Drizzle with honey"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_4",
                name: "Hummus with Vegetables",
                calories: 120,
                detail: "Fresh vegetable sticks with classic hummus dip",
                nutrition: NutritionInfo(protein: 6, carbs: 16, fats: 6),
                imageName: "https://images.unsplash.com/photo-1571197119282-7c4a3c2e3b3e?w=400",
                cookTime: 5,
                isFavorite: false,
                ingredients: ["carrots", "celery", "cucumber", "hummus"],
                instructions: ["Cut vegetables into sticks", "Serve with hummus"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_5",
                name: "Cheese and Crackers",
                calories: 200,
                detail: "Assorted cheese cubes with whole grain crackers",
                nutrition: NutritionInfo(protein: 10, carbs: 16, fats: 12),
                imageName: "https://images.unsplash.com/photo-1559561853-08451507cbe7?w=400",
                cookTime: 3,
                isFavorite: true,
                ingredients: ["cheddar cheese", "whole grain crackers"],
                instructions: ["Cut cheese into cubes", "Arrange with crackers"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_6",
                name: "Trail Mix",
                calories: 190,
                detail: "Homemade trail mix with nuts, seeds, and dried fruit",
                nutrition: NutritionInfo(protein: 7, carbs: 18, fats: 12),
                imageName: "https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=400",
                cookTime: 2,
                isFavorite: false,
                ingredients: ["almonds", "sunflower seeds", "dried cranberries", "dark chocolate chips"],
                instructions: ["Mix all ingredients", "Store in airtight container"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_7",
                name: "Banana Smoothie",
                calories: 160,
                detail: "Creamy banana smoothie with almond milk",
                nutrition: NutritionInfo(protein: 4, carbs: 32, fats: 4),
                imageName: "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400",
                cookTime: 3,
                isFavorite: true,
                ingredients: ["1 banana", "1 cup almond milk", "1 tsp honey", "ice cubes"],
                instructions: ["Blend banana with almond milk", "Add honey and ice", "Blend until smooth"],
                category: "Snacks"
            )
        ]
        
        // Combine all meals
        meals.append(contentsOf: breakfastMeals)
        meals.append(contentsOf: lunchMeals)
        meals.append(contentsOf: dinnerMeals)
        meals.append(contentsOf: snackMeals)
        
        return meals
    }
    
    func uploadMockRecipesToFirebase() {
        let db = Firestore.firestore()
        let recipes = generateSampleMeals()
        let collectionRef = db.collection("recipesDemo")

        for recipe in recipes {
            do {
                try collectionRef.document(recipe.id).setData(from: recipe) { error in
                    if let error = error {
                        print("❌ Error uploading \(recipe.name): \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully uploaded \(recipe.name)")
                    }
                }
            } catch {
                print("❌ Encoding error for \(recipe.name): \(error.localizedDescription)")
            }
        }
    }
    
    func fetchFoodDiaries() async throws -> [String: FoodDiary] {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user UID")
            return [:]
        }
        
        var result: [String: FoodDiary] = [:]

        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("FoodDiary")
            .getDocuments()

        for doc in snapshot.documents {
            print("Doc ID: \(doc.documentID)")
            print("Data: \(doc.data())")
            
            let jsonData = try JSONSerialization.data(withJSONObject: doc.data(), options: [])
            let diary = try JSONDecoder().decode(FoodDiary.self, from: jsonData)
            result[doc.documentID] = diary
        }
        
        
        return result
    }

}

struct LoginResponseREST: Codable {
    let userId: String?
    let detail: String?
    let token: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case detail, token, error
    }
}

struct UserProfile: Codable {
    var id: String
    var name: String
    var email: String
    var avatarImage: URL?
    var height: Int?
    var weight: Double
    var gender: String?
    var birthDate: Date?
    var currentGoal: String?
    var targetWeight: Double
}

// Универсальная функция для сохранения моделей в Firestore
extension Firestore {
    func save<T: Codable>(_ model: T, toCollection collection: String, withDocumentId id: String) async throws {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(model)
        
        // Преобразуем данные в [String: Any], которые Firestore принимает
        let dataDictionary = try JSONSerialization.jsonObject(with: encodedData, options: []) as! [String: Any]
        
        // Сохраняем данные в Firestore
        try await self.collection(collection).document(id).setData(dataDictionary)
    }
}

extension Notification.Name {
    static let shouldFetchHomeData = Notification.Name("shouldFetchHomeData")
    static let getProfile = Notification.Name("getProfile")
}
