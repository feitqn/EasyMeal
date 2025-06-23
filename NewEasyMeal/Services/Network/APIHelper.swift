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
        let docRef = db.collection("recipesNewFood").document(recipeId)

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
        let snapshot = try await db.collection("recipesNewFood").getDocuments()

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
            // ЯЙЦА (3 варианта)
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
                id: "breakfast_1a",
                name: "Fried Eggs with Bacon",
                calories: 420,
                detail: "Sunny-side up eggs with crispy bacon strips",
                nutrition: NutritionInfo(protein: 22, carbs: 8, fats: 35),
                imageName: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400",
                cookTime: 12,
                isFavorite: true,
                ingredients: ["2 eggs", "3 bacon strips", "1 tbsp oil", "salt", "pepper", "fresh herbs"],
                instructions: ["Cook bacon until crispy", "Fry eggs in bacon fat", "Season with salt and pepper", "Garnish with herbs", "Serve immediately"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_1b",
                name: "Vegetable Omelet",
                calories: 310,
                detail: "Fluffy omelet filled with fresh vegetables and cheese",
                nutrition: NutritionInfo(protein: 20, carbs: 12, fats: 22),
                imageName: "https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["3 eggs", "1/4 cup cheese", "bell pepper", "onion", "spinach", "mushrooms"],
                instructions: ["Sauté vegetables", "Beat eggs with salt", "Pour eggs in pan", "Add vegetables and cheese", "Fold omelet in half"],
                category: "Breakfast"
            ),
            
            // ОВСЯНКА (3 варианта)
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
                id: "breakfast_2a",
                name: "Chocolate Banana Oatmeal",
                calories: 340,
                detail: "Rich chocolate oatmeal with sliced bananas and cocoa powder",
                nutrition: NutritionInfo(protein: 10, carbs: 58, fats: 8),
                imageName: "https://images.unsplash.com/photo-1574653339161-f7c2b8f9fb75?w=400",
                cookTime: 10,
                isFavorite: true,
                ingredients: ["1 cup oats", "2 cups milk", "2 tbsp cocoa powder", "1 banana", "2 tbsp maple syrup", "dark chocolate chips"],
                instructions: ["Cook oats with milk", "Stir in cocoa powder", "Add maple syrup", "Top with banana slices", "Sprinkle chocolate chips"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_2b",
                name: "Apple Cinnamon Oatmeal",
                calories: 300,
                detail: "Warm spiced oatmeal with caramelized apples and cinnamon",
                nutrition: NutritionInfo(protein: 9, carbs: 55, fats: 7),
                imageName: "https://images.unsplash.com/photo-1559847844-5315695dadae?w=400",
                cookTime: 12,
                isFavorite: false,
                ingredients: ["1 cup oats", "2 cups milk", "1 apple diced", "1 tsp cinnamon", "2 tbsp brown sugar", "walnuts"],
                instructions: ["Sauté apple with cinnamon", "Cook oats separately", "Combine oats and apples", "Add brown sugar", "Top with walnuts"],
                category: "Breakfast"
            ),
            
            // ЙОГУРТ (3 варианта)
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
                id: "breakfast_3a",
                name: "Vanilla Yogurt Bowl",
                calories: 250,
                detail: "Creamy vanilla yogurt with toasted nuts and dried fruits",
                nutrition: NutritionInfo(protein: 12, carbs: 32, fats: 10),
                imageName: "https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400",
                cookTime: 3,
                isFavorite: true,
                ingredients: ["1 cup vanilla yogurt", "2 tbsp almonds", "2 tbsp dried cranberries", "1 tsp vanilla extract", "coconut flakes"],
                instructions: ["Place yogurt in bowl", "Add vanilla extract", "Top with almonds", "Sprinkle dried cranberries", "Add coconut flakes"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_3b",
                name: "Berry Yogurt Smoothie Bowl",
                calories: 270,
                detail: "Thick berry yogurt smoothie topped with fresh fruits and seeds",
                nutrition: NutritionInfo(protein: 14, carbs: 35, fats: 9),
                imageName: "https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400",
                cookTime: 7,
                isFavorite: false,
                ingredients: ["1 cup berry yogurt", "1/2 cup frozen berries", "1 tbsp chia seeds", "fresh strawberries", "mint leaves"],
                instructions: ["Blend yogurt with frozen berries", "Pour into bowl", "Top with fresh strawberries", "Sprinkle chia seeds", "Garnish with mint"],
                category: "Breakfast"
            ),
            
            // ТОСТЫ (3 варианта)
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
                id: "breakfast_4a",
                name: "Peanut Butter Banana Toast",
                calories: 380,
                detail: "Whole grain toast with creamy peanut butter and banana slices",
                nutrition: NutritionInfo(protein: 12, carbs: 42, fats: 18),
                imageName: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400",
                cookTime: 5,
                isFavorite: true,
                ingredients: ["2 slices whole grain bread", "3 tbsp peanut butter", "1 banana", "honey", "cinnamon", "chopped peanuts"],
                instructions: ["Toast bread slices", "Spread peanut butter evenly", "Add banana slices", "Drizzle with honey", "Sprinkle cinnamon and peanuts"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_4b",
                name: "Cream Cheese Berry Toast",
                calories: 290,
                detail: "Toasted bagel with cream cheese and fresh mixed berries",
                nutrition: NutritionInfo(protein: 11, carbs: 35, fats: 12),
                imageName: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400",
                cookTime: 6,
                isFavorite: false,
                ingredients: ["1 everything bagel", "3 tbsp cream cheese", "1/2 cup mixed berries", "mint leaves", "powdered sugar"],
                instructions: ["Toast bagel halves", "Spread cream cheese", "Top with fresh berries", "Garnish with mint", "Dust with powdered sugar"],
                category: "Breakfast"
            ),
            
            // БЛИНЧИКИ (3 варианта)
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
                id: "breakfast_5a",
                name: "Blueberry Pancakes",
                calories: 480,
                detail: "Light and fluffy pancakes bursting with fresh blueberries",
                nutrition: NutritionInfo(protein: 13, carbs: 72, fats: 17),
                imageName: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["2 cups flour", "2 eggs", "1.5 cups milk", "1 cup blueberries", "3 tbsp sugar", "baking powder"],
                instructions: ["Mix dry ingredients", "Combine wet ingredients", "Fold in blueberries gently", "Cook on medium heat", "Serve with butter and syrup"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_5b",
                name: "Protein Banana Pancakes",
                calories: 380,
                detail: "Healthy protein-packed pancakes made with banana and oats",
                nutrition: NutritionInfo(protein: 18, carbs: 45, fats: 12),
                imageName: "https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400",
                cookTime: 15,
                isFavorite: false,
                ingredients: ["1 cup oats", "2 bananas", "3 eggs", "1 scoop protein powder", "1 tsp vanilla", "cinnamon"],
                instructions: ["Blend all ingredients", "Let batter rest 5 minutes", "Cook small pancakes", "Flip when bubbles form", "Serve with fresh fruit"],
                category: "Breakfast"
            ),
            
            // СМУЗИ БОУЛЫ (3 варианта)
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
                id: "breakfast_6a",
                name: "Green Power Smoothie Bowl",
                calories: 320,
                detail: "Nutrient-packed green smoothie with spinach, avocado, and tropical fruits",
                nutrition: NutritionInfo(protein: 12, carbs: 38, fats: 16),
                imageName: "https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=400",
                cookTime: 8,
                isFavorite: true,
                ingredients: ["1 cup spinach", "1/2 avocado", "1 banana", "1/2 cup pineapple", "coconut milk", "hemp seeds"],
                instructions: ["Blend greens with coconut milk", "Add fruits and blend smooth", "Pour into bowl", "Top with hemp seeds", "Add fresh fruit slices"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_6b",
                name: "Chocolate Peanut Butter Bowl",
                calories: 410,
                detail: "Rich chocolate smoothie bowl with peanut butter and banana",
                nutrition: NutritionInfo(protein: 15, carbs: 42, fats: 20),
                imageName: "https://images.unsplash.com/photo-1623042045404-6f96e30f87b5?w=400",
                cookTime: 7,
                isFavorite: false,
                ingredients: ["1 frozen banana", "2 tbsp cocoa powder", "2 tbsp peanut butter", "almond milk", "granola", "dark chocolate chips"],
                instructions: ["Blend banana with cocoa and PB", "Add milk gradually", "Pour into bowl", "Top with granola", "Sprinkle chocolate chips"],
                category: "Breakfast"
            ),
            
            // ФРАНЦУЗСКИЕ ТОСТЫ (3 варианта)
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
            ),
            FoodItem(
                id: "breakfast_7a",
                name: "Stuffed French Toast",
                calories: 520,
                detail: "Decadent French toast stuffed with cream cheese and strawberries",
                nutrition: NutritionInfo(protein: 16, carbs: 58, fats: 25),
                imageName: "https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400",
                cookTime: 20,
                isFavorite: true,
                ingredients: ["8 slices thick bread", "4 oz cream cheese", "1 cup strawberries", "4 eggs", "milk", "vanilla extract"],
                instructions: ["Make cream cheese filling", "Stuff bread slices", "Dip in egg mixture", "Cook until golden", "Serve with berry compote"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_7b",
                name: "Banana Foster French Toast",
                calories: 460,
                detail: "Caramelized banana French toast with rum sauce",
                nutrition: NutritionInfo(protein: 12, carbs: 62, fats: 18),
                imageName: "https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400",
                cookTime: 18,
                isFavorite: true,
                ingredients: ["4 slices challah bread", "2 bananas", "3 eggs", "brown sugar", "butter", "rum extract"],
                instructions: ["Caramelize bananas with sugar", "Make egg mixture with rum", "Dip bread and cook", "Top with caramelized bananas", "Drizzle with caramel sauce"],
                category: "Breakfast"
            ),
            
            // МЮСЛИ И ГРАНОЛА (3 варианта)
            FoodItem(
                id: "breakfast_8",
                name: "Homemade Granola Bowl",
                calories: 350,
                detail: "Crunchy homemade granola with nuts, seeds, and dried fruits",
                nutrition: NutritionInfo(protein: 11, carbs: 45, fats: 15),
                imageName: "https://images.unsplash.com/photo-1559181567-c3190ca9959b?w=400",
                cookTime: 5,
                isFavorite: true,
                ingredients: ["1/2 cup granola", "1 cup milk", "2 tbsp almonds", "1 tbsp raisins", "1 tbsp honey", "fresh berries"],
                instructions: ["Place granola in bowl", "Pour cold milk", "Top with almonds and raisins", "Add fresh berries", "Drizzle with honey"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_8a",
                name: "Tropical Muesli",
                calories: 310,
                detail: "Raw muesli soaked overnight with tropical fruits and coconut",
                nutrition: NutritionInfo(protein: 9, carbs: 52, fats: 8),
                imageName: "https://images.unsplash.com/photo-1571197107998-291b0660fe9c?w=400",
                cookTime: 2,
                isFavorite: false,
                ingredients: ["1/2 cup muesli", "coconut milk", "diced mango", "pineapple chunks", "coconut flakes", "lime zest"],
                instructions: ["Soak muesli overnight", "Add coconut milk", "Top with tropical fruits", "Sprinkle coconut flakes", "Add lime zest"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_8b",
                name: "Chocolate Granola Yogurt",
                calories: 390,
                detail: "Rich chocolate granola layered with vanilla yogurt",
                nutrition: NutritionInfo(protein: 13, carbs: 48, fats: 16),
                imageName: "https://images.unsplash.com/photo-1607077284310-6e8c0b18ad2d?w=400",
                cookTime: 3,
                isFavorite: true,
                ingredients: ["1/2 cup chocolate granola", "1 cup vanilla yogurt", "dark chocolate chips", "sliced almonds", "honey"],
                instructions: ["Layer yogurt and granola", "Repeat layers", "Top with chocolate chips", "Add sliced almonds", "Drizzle with honey"],
                category: "Breakfast"
            ),
            
            // КЕКСЫ И МАФФИНЫ (3 варианта)
            FoodItem(
                id: "breakfast_9",
                name: "Blueberry Muffins",
                calories: 320,
                detail: "Fluffy homemade muffins bursting with fresh blueberries",
                nutrition: NutritionInfo(protein: 6, carbs: 48, fats: 12),
                imageName: "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["2 cups flour", "1 cup blueberries", "1/2 cup sugar", "2 eggs", "milk", "baking powder"],
                instructions: ["Mix dry ingredients", "Combine wet ingredients", "Fold in blueberries", "Fill muffin cups", "Bake until golden"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_9a",
                name: "Banana Nut Muffins",
                calories: 340,
                detail: "Moist banana muffins with crunchy walnuts and cinnamon",
                nutrition: NutritionInfo(protein: 7, carbs: 52, fats: 14),
                imageName: "https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400",
                cookTime: 22,
                isFavorite: false,
                ingredients: ["2 ripe bananas", "2 cups flour", "1/2 cup walnuts", "2 eggs", "brown sugar", "cinnamon"],
                instructions: ["Mash bananas", "Mix all ingredients", "Add walnuts", "Bake in muffin tins", "Cool before serving"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_9b",
                name: "Lemon Poppy Seed Muffins",
                calories: 310,
                detail: "Light and zesty muffins with fresh lemon and poppy seeds",
                nutrition: NutritionInfo(protein: 5, carbs: 46, fats: 12),
                imageName: "https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["2 cups flour", "2 tbsp poppy seeds", "lemon zest", "2 eggs", "sugar", "lemon juice"],
                instructions: ["Zest fresh lemon", "Mix dry ingredients", "Combine wet ingredients", "Fold everything together", "Bake until tops spring back"],
                category: "Breakfast"
            ),
            
            // ВАФЛИ (3 варианта)
            FoodItem(
                id: "breakfast_10",
                name: "Classic Belgian Waffles",
                calories: 420,
                detail: "Crispy outside, fluffy inside waffles with syrup and butter",
                nutrition: NutritionInfo(protein: 10, carbs: 58, fats: 18),
                imageName: "https://images.unsplash.com/photo-1562376552-0d160dcec1d4?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["2 cups flour", "2 eggs", "1.5 cups milk", "4 tbsp melted butter", "2 tbsp sugar", "baking powder"],
                instructions: ["Heat waffle iron", "Mix batter ingredients", "Pour onto waffle iron", "Cook until golden", "Serve with syrup and butter"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_10a",
                name: "Strawberry Cream Waffles",
                calories: 480,
                detail: "Golden waffles topped with fresh strawberries and whipped cream",
                nutrition: NutritionInfo(protein: 9, carbs: 62, fats: 22),
                imageName: "https://images.unsplash.com/photo-1605811849663-5c7c8db92c17?w=400",
                cookTime: 18,
                isFavorite: true,
                ingredients: ["waffle batter", "2 cups strawberries", "whipped cream", "powdered sugar", "vanilla extract"],
                instructions: ["Make waffles", "Slice fresh strawberries", "Whip cream with vanilla", "Top waffles with berries", "Add dollop of cream"],
                category: "Breakfast"
            ),
            FoodItem(
                id: "breakfast_10b",
                name: "Chocolate Chip Waffles",
                calories: 450,
                detail: "Indulgent waffles loaded with chocolate chips",
                nutrition: NutritionInfo(protein: 11, carbs: 60, fats: 19),
                imageName: "https://images.unsplash.com/photo-1509365465985-25d11c17e812?w=400",
                cookTime: 16,
                isFavorite: false,
                ingredients: ["waffle batter", "1/2 cup chocolate chips", "2 tbsp cocoa powder", "vanilla extract", "maple syrup"],
                instructions: ["Add cocoa to batter", "Fold in chocolate chips", "Cook in waffle iron", "Drizzle with syrup", "Serve warm"],
                category: "Breakfast"
            )
        ]
        
        // LUNCH MEALS (7)
        let lunchMeals = [
            // САЛАТЫ (3 варианта)
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
                id: "lunch_1a",
                name: "Greek Salad",
                calories: 350,
                detail: "Traditional Greek salad with feta, olives, and Mediterranean vegetables",
                nutrition: NutritionInfo(protein: 12, carbs: 15, fats: 28),
                imageName: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400",
                cookTime: 10,
                isFavorite: true,
                ingredients: ["mixed greens", "feta cheese", "kalamata olives", "cucumber", "cherry tomatoes", "red onion", "olive oil"],
                instructions: ["Chop all vegetables", "Crumble feta cheese", "Add olives and onion", "Drizzle with olive oil", "Toss gently and serve"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_1b",
                name: "Cobb Salad",
                calories: 480,
                detail: "Hearty American salad with bacon, blue cheese, and hard-boiled eggs",
                nutrition: NutritionInfo(protein: 24, carbs: 12, fats: 38),
                imageName: "https://images.unsplash.com/photo-1512852939750-1305098529bf?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["mixed lettuce", "grilled chicken", "bacon", "blue cheese", "hard-boiled eggs", "avocado", "tomatoes"],
                instructions: ["Arrange lettuce in bowl", "Cook and chop bacon", "Slice chicken and eggs", "Add all toppings in rows", "Serve with dressing"],
                category: "Lunch"
            ),
            
            // СЭНДВИЧИ (3 варианта)
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
                id: "lunch_2a",
                name: "BLT Sandwich",
                calories: 420,
                detail: "Classic bacon, lettuce, and tomato sandwich on toasted bread",
                nutrition: NutritionInfo(protein: 18, carbs: 35, fats: 28),
                imageName: "https://images.unsplash.com/photo-1553909489-cd47e0ef937f?w=400",
                cookTime: 12,
                isFavorite: true,
                ingredients: ["8 strips bacon", "4 slices bread", "lettuce leaves", "2 large tomatoes", "mayo", "salt", "pepper"],
                instructions: ["Cook bacon until crispy", "Toast bread slices", "Spread mayo on toast", "Layer lettuce and tomato", "Add crispy bacon"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_2b",
                name: "Veggie Panini",
                calories: 380,
                detail: "Grilled vegetable panini with mozzarella and pesto",
                nutrition: NutritionInfo(protein: 16, carbs: 38, fats: 22),
                imageName: "https://images.unsplash.com/photo-1621504450181-5d356f61d307?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["focaccia bread", "zucchini", "bell peppers", "eggplant", "mozzarella", "pesto", "olive oil"],
                instructions: ["Slice vegetables thin", "Brush with olive oil", "Grill vegetables", "Spread pesto on bread", "Layer with cheese and grill"],
                category: "Lunch"
            ),
            
            // БОУЛЫ (3 варианта)
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
                id: "lunch_3a",
                name: "Buddha Bowl",
                calories: 450,
                detail: "Colorful Buddha bowl with brown rice, roasted vegetables, and avocado",
                nutrition: NutritionInfo(protein: 16, carbs: 58, fats: 18),
                imageName: "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=400",
                cookTime: 35,
                isFavorite: true,
                ingredients: ["brown rice", "sweet potato", "broccoli", "avocado", "edamame", "sesame seeds", "ginger dressing"],
                instructions: ["Cook brown rice", "Roast sweet potato and broccoli", "Prepare ginger dressing", "Arrange in bowl", "Top with avocado and seeds"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_3b",
                name: "Poke Bowl",
                calories: 420,
                detail: "Fresh Hawaiian poke bowl with sushi-grade tuna and rice",
                nutrition: NutritionInfo(protein: 26, carbs: 48, fats: 12),
                imageName: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["sushi rice", "fresh tuna", "cucumber", "avocado", "edamame", "nori", "soy sauce", "sesame oil"],
                instructions: ["Prepare sushi rice", "Cube fresh tuna", "Slice cucumber and avocado", "Mix tuna with soy sauce", "Assemble bowl with toppings"],
                category: "Lunch"
            ),
            
            // КЛУБНЫЕ СЭНДВИЧИ (3 варианта)
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
                id: "lunch_4a",
                name: "Italian Club Sandwich",
                calories: 580,
                detail: "Italian-style club with salami, ham, provolone, and peppers",
                nutrition: NutritionInfo(protein: 32, carbs: 42, fats: 32),
                imageName: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400",
                cookTime: 10,
                isFavorite: true,
                ingredients: ["ciabatta bread", "salami", "ham", "provolone cheese", "roasted peppers", "arugula", "olive tapenade"],
                instructions: ["Slice ciabatta horizontally", "Spread olive tapenade", "Layer meats and cheese", "Add peppers and arugula", "Cut and serve"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_4b",
                name: "Veggie Club Sandwich",
                calories: 440,
                detail: "Vegetarian club with hummus, sprouts, and fresh vegetables",
                nutrition: NutritionInfo(protein: 18, carbs: 52, fats: 20),
                imageName: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400",
                cookTime: 8,
                isFavorite: false,
                ingredients: ["whole grain bread", "hummus", "avocado", "cucumber", "sprouts", "tomato", "lettuce", "cheese"],
                instructions: ["Toast bread lightly", "Spread hummus generously", "Layer vegetables", "Add cheese and sprouts", "Cut diagonally"],
                category: "Lunch"
            ),
            
            // ПАСТА (3 варианта)
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
                id: "lunch_5a",
                name: "Spaghetti Carbonara",
                calories: 520,
                detail: "Classic Italian pasta with eggs, pancetta, and parmesan",
                nutrition: NutritionInfo(protein: 22, carbs: 52, fats: 26),
                imageName: "https://images.unsplash.com/photo-1551892374-ecf8754cf8b0?w=400",
                cookTime: 20,
                isFavorite: true,
                ingredients: ["spaghetti", "pancetta", "eggs", "parmesan cheese", "black pepper", "olive oil"],
                instructions: ["Cook pasta al dente", "Crisp pancetta in pan", "Whisk eggs with cheese", "Toss hot pasta with egg mixture", "Add pancetta and pepper"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_5b",
                name: "Pesto Pasta Salad",
                calories: 380,
                detail: "Cold pasta salad with homemade pesto and cherry tomatoes",
                nutrition: NutritionInfo(protein: 14, carbs: 46, fats: 16),
                imageName: "https://images.unsplash.com/photo-1563379091339-03246963d96c?w=400",
                cookTime: 15,
                isFavorite: false,
                ingredients: ["pasta shells", "basil pesto", "cherry tomatoes", "mozzarella balls", "pine nuts", "olive oil"],
                instructions: ["Cook pasta and cool", "Halve cherry tomatoes", "Mix pasta with pesto", "Add tomatoes and mozzarella", "Garnish with pine nuts"],
                category: "Lunch"
            ),
            
            // ТАКО (3 варианта)
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
                id: "lunch_6a",
                name: "Chicken Tacos",
                calories: 420,
                detail: "Spicy grilled chicken tacos with salsa and avocado",
                nutrition: NutritionInfo(protein: 28, carbs: 32, fats: 20),
                imageName: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400",
                cookTime: 20,
                isFavorite: true,
                ingredients: ["chicken thighs", "flour tortillas", "salsa", "avocado", "onion", "cilantro", "lime", "chili powder"],
                instructions: ["Marinate chicken with spices", "Grill chicken until done", "Warm tortillas", "Slice avocado", "Assemble with salsa and toppings"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_6b",
                name: "Vegetarian Black Bean Tacos",
                calories: 340,
                detail: "Hearty black bean tacos with corn salsa and cheese",
                nutrition: NutritionInfo(protein: 16, carbs: 48, fats: 12),
                imageName: "https://images.unsplash.com/photo-1565299507177-b0ac66763368?w=400",
                cookTime: 15,
                isFavorite: false,
                ingredients: ["black beans", "corn tortillas", "corn kernels", "bell peppers", "cheese", "lime", "cumin", "chili powder"],
                instructions: ["Season and heat black beans", "Make corn salsa", "Warm tortillas", "Fill with beans", "Top with salsa and cheese"],
                category: "Lunch"
            ),
            
            // РИЗОТТО (3 варианта)
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
            ),
            FoodItem(
                id: "lunch_7a",
                name: "Seafood Risotto",
                calories: 480,
                detail: "Luxurious risotto with mixed seafood and saffron",
                nutrition: NutritionInfo(protein: 26, carbs: 48, fats: 18),
                imageName: "https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400",
                cookTime: 40,
                isFavorite: true,
                ingredients: ["Arborio rice", "mixed seafood", "fish stock", "saffron", "white wine", "shallots", "butter", "parsley"],
                instructions: ["Soak saffron in warm stock", "Sauté shallots", "Toast rice", "Add wine and saffron stock", "Stir in cooked seafood"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_7b",
                name: "Lemon Asparagus Risotto",
                calories: 390,
                detail: "Light and fresh risotto with asparagus and lemon zest",
                nutrition: NutritionInfo(protein: 14, carbs: 52, fats: 14),
                imageName: "https://images.unsplash.com/photo-1550317138-10000687ac18?w=400",
                cookTime: 30,
                isFavorite: false,
                ingredients: ["Arborio rice", "asparagus", "vegetable broth", "lemon zest", "lemon juice", "parmesan", "butter"],
                instructions: ["Blanch asparagus", "Sauté onion and rice", "Add broth gradually", "Stir in asparagus", "Finish with lemon and cheese"],
                category: "Lunch"
            ),
            
            // СУПЫ (3 варианта)
            FoodItem(
                id: "lunch_8",
                name: "Tomato Basil Soup",
                calories: 250,
                detail: "Classic creamy tomato soup with fresh basil",
                nutrition: NutritionInfo(protein: 8, carbs: 28, fats: 12),
                imageName: "https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["canned tomatoes", "fresh basil", "heavy cream", "onion", "garlic", "vegetable broth", "olive oil"],
                instructions: ["Sauté onion and garlic", "Add tomatoes and broth", "Simmer 20 minutes", "Blend until smooth", "Stir in cream and basil"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_8a",
                name: "Chicken Noodle Soup",
                calories: 320,
                detail: "Comforting chicken soup with vegetables and egg noodles",
                nutrition: NutritionInfo(protein: 22, carbs: 32, fats: 10),
                imageName: "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400",
                cookTime: 45,
                isFavorite: true,
                ingredients: ["chicken breast", "egg noodles", "carrots", "celery", "onion", "chicken broth", "parsley"],
                instructions: ["Simmer chicken in broth", "Remove and shred chicken", "Cook vegetables in broth", "Add noodles and chicken", "Season and serve"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_8b",
                name: "Butternut Squash Soup",
                calories: 280,
                detail: "Velvety butternut squash soup with warming spices",
                nutrition: NutritionInfo(protein: 6, carbs: 42, fats: 12),
                imageName: "https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=400",
                cookTime: 35,
                isFavorite: false,
                ingredients: ["butternut squash", "onion", "apple", "ginger", "vegetable broth", "coconut milk", "cinnamon"],
                instructions: ["Roast cubed squash", "Sauté onion and apple", "Add broth and simmer", "Blend until smooth", "Stir in coconut milk"],
                category: "Lunch"
            ),
            
            // КАРРИ (3 варианта)
            FoodItem(
                id: "lunch_9",
                name: "Chicken Curry",
                calories: 450,
                detail: "Aromatic chicken curry with coconut milk and spices",
                nutrition: NutritionInfo(protein: 32, carbs: 18, fats: 28),
                imageName: "https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=400",
                cookTime: 30,
                isFavorite: true,
                ingredients: ["chicken thighs", "coconut milk", "curry powder", "onion", "garlic", "ginger", "tomatoes", "cilantro"],
                instructions: ["Brown chicken pieces", "Sauté onion, garlic, ginger", "Add curry powder and tomatoes", "Simmer with coconut milk", "Garnish with cilantro"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_9a",
                name: "Vegetable Thai Curry",
                calories: 380,
                detail: "Colorful vegetable curry with Thai red curry paste",
                nutrition: NutritionInfo(protein: 12, carbs: 35, fats: 24),
                imageName: "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["mixed vegetables", "coconut milk", "red curry paste", "bell peppers", "bamboo shoots", "thai basil", "lime"],
                instructions: ["Heat curry paste in oil", "Add vegetables", "Pour in coconut milk", "Simmer until tender", "Finish with basil and lime"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_9b",
                name: "Lentil Curry",
                calories: 320,
                detail: "Hearty lentil curry with turmeric and warm spices",
                nutrition: NutritionInfo(protein: 18, carbs: 48, fats: 8),
                imageName: "https://images.unsplash.com/photo-1574653339261-f7c2b8f9fb75?w=400",
                cookTime: 40,
                isFavorite: false,
                ingredients: ["red lentils", "onion", "garlic", "turmeric", "cumin", "coriander", "coconut milk", "spinach"],
                instructions: ["Cook lentils until soft", "Sauté onion and spices", "Combine lentils with spice mix", "Add coconut milk", "Stir in spinach"],
                category: "Lunch"
            ),
            
            // РАМЕН (3 варианта)
            FoodItem(
                id: "lunch_10",
                name: "Chicken Ramen",
                calories: 420,
                detail: "Rich chicken ramen with soft-boiled egg and vegetables",
                nutrition: NutritionInfo(protein: 25, carbs: 48, fats: 14),
                imageName: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400",
                cookTime: 35,
                isFavorite: true,
                ingredients: ["ramen noodles", "chicken broth", "chicken breast", "soft-boiled eggs", "green onions", "nori", "bamboo shoots"],
                instructions: ["Prepare rich chicken broth", "Cook noodles separately", "Slice chicken and eggs", "Assemble in bowls", "Garnish with toppings"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_10a",
                name: "Vegetarian Miso Ramen",
                calories: 380,
                detail: "Umami-rich miso ramen with tofu and vegetables",
                nutrition: NutritionInfo(protein: 18, carbs: 52, fats: 12),
                imageName: "https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=400",
                cookTime: 30,
                isFavorite: false,
                ingredients: ["ramen noodles", "miso paste", "vegetable broth", "tofu", "mushrooms", "corn", "green onions"],
                instructions: ["Make miso broth", "Pan-fry tofu", "Cook vegetables", "Prepare noodles", "Combine and serve hot"],
                category: "Lunch"
            ),
            FoodItem(
                id: "lunch_10b",
                name: "Spicy Pork Ramen",
                calories: 480,
                detail: "Fiery pork ramen with kimchi and chili oil",
                nutrition: NutritionInfo(protein: 28, carbs: 46, fats: 20),
                imageName: "https://images.unsplash.com/photo-1623341214825-83e5e6b0c84e?w=400",
                cookTime: 40,
                isFavorite: true,
                ingredients: ["ramen noodles", "pork belly", "kimchi", "chili oil", "garlic", "soy sauce", "soft-boiled egg"],
                instructions: ["Braise pork belly", "Make spicy broth", "Cook noodles", "Add kimchi and chili oil", "Top with egg and pork"],
                category: "Lunch"
            )
        ]
        
        // DINNER MEALS (7)
        let dinnerMeals = [
            // Salmon variations
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
                name: "Teriyaki Salmon",
                calories: 540,
                detail: "Glazed salmon with teriyaki sauce and steamed broccoli",
                nutrition: NutritionInfo(protein: 40, carbs: 32, fats: 24),
                imageName: "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["6 oz salmon fillet", "teriyaki sauce", "broccoli", "rice", "sesame seeds", "ginger"],
                instructions: ["Marinate salmon in teriyaki", "Steam broccoli", "Cook rice", "Pan-fry salmon", "Glaze and serve"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_3",
                name: "Smoked Salmon Pasta",
                calories: 480,
                detail: "Creamy pasta with smoked salmon and capers",
                nutrition: NutritionInfo(protein: 28, carbs: 45, fats: 18),
                imageName: "https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["smoked salmon", "pasta", "cream", "capers", "dill", "lemon", "onion"],
                instructions: ["Cook pasta", "Sauté onion", "Add cream and capers", "Fold in salmon", "Garnish with dill"],
                category: "Dinner"
            ),
            
            // Beef variations
            FoodItem(
                id: "dinner_4",
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
                id: "dinner_5",
                name: "Beef Stroganoff",
                calories: 520,
                detail: "Creamy beef stroganoff with mushrooms over egg noodles",
                nutrition: NutritionInfo(protein: 35, carbs: 42, fats: 22),
                imageName: "https://images.unsplash.com/photo-1572441713132-51c75654db73?w=400",
                cookTime: 35,
                isFavorite: true,
                ingredients: ["beef strips", "mushrooms", "sour cream", "egg noodles", "onion", "beef broth", "flour"],
                instructions: ["Brown beef strips", "Sauté mushrooms and onion", "Make cream sauce", "Combine all ingredients", "Serve over noodles"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_6",
                name: "Beef Tacos",
                calories: 440,
                detail: "Seasoned ground beef tacos with fresh toppings",
                nutrition: NutritionInfo(protein: 30, carbs: 35, fats: 20),
                imageName: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400",
                cookTime: 25,
                isFavorite: false,
                ingredients: ["ground beef", "taco shells", "lettuce", "tomatoes", "cheese", "salsa", "sour cream"],
                instructions: ["Brown ground beef", "Season with spices", "Warm taco shells", "Prepare toppings", "Assemble tacos"],
                category: "Dinner"
            ),
            
            // Chicken variations
            FoodItem(
                id: "dinner_7",
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
                id: "dinner_8",
                name: "Chicken Alfredo",
                calories: 620,
                detail: "Creamy chicken alfredo pasta with garlic and herbs",
                nutrition: NutritionInfo(protein: 42, carbs: 48, fats: 28),
                imageName: "https://images.unsplash.com/photo-1621852004158-f3bc188ace2d?w=400",
                cookTime: 30,
                isFavorite: true,
                ingredients: ["chicken breast", "fettuccine", "heavy cream", "parmesan", "garlic", "butter", "parsley"],
                instructions: ["Cook chicken breast", "Prepare alfredo sauce", "Cook pasta", "Combine all ingredients", "Garnish with parsley"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_9",
                name: "Chicken Curry",
                calories: 450,
                detail: "Spicy chicken curry with coconut milk and basmati rice",
                nutrition: NutritionInfo(protein: 38, carbs: 35, fats: 18),
                imageName: "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400",
                cookTime: 45,
                isFavorite: false,
                ingredients: ["chicken thighs", "coconut milk", "curry powder", "onion", "tomatoes", "basmati rice", "cilantro"],
                instructions: ["Brown chicken pieces", "Sauté onion and spices", "Add tomatoes and coconut milk", "Simmer chicken", "Serve with rice"],
                category: "Dinner"
            ),
            
            // Vegetable Curry variations
            FoodItem(
                id: "dinner_10",
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
                id: "dinner_11",
                name: "Thai Green Curry",
                calories: 420,
                detail: "Spicy Thai green curry with eggplant and bamboo shoots",
                nutrition: NutritionInfo(protein: 14, carbs: 52, fats: 18),
                imageName: "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400",
                cookTime: 25,
                isFavorite: false,
                ingredients: ["green curry paste", "eggplant", "bamboo shoots", "coconut milk", "thai basil", "jasmine rice"],
                instructions: ["Heat curry paste", "Add vegetables", "Pour coconut milk", "Simmer until fragrant", "Garnish with basil"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_12",
                name: "Indian Dal Curry",
                calories: 340,
                detail: "Hearty lentil curry with aromatic spices and naan",
                nutrition: NutritionInfo(protein: 18, carbs: 48, fats: 8),
                imageName: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400",
                cookTime: 40,
                isFavorite: true,
                ingredients: ["red lentils", "turmeric", "cumin", "coriander", "tomatoes", "onion", "naan bread"],
                instructions: ["Cook lentils with spices", "Sauté onion and tomatoes", "Combine with lentils", "Simmer until thick", "Serve with naan"],
                category: "Dinner"
            ),
            
            // Pork variations
            FoodItem(
                id: "dinner_13",
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
                id: "dinner_14",
                name: "Pork Chops",
                calories: 460,
                detail: "Pan-seared pork chops with apple sauce and green beans",
                nutrition: NutritionInfo(protein: 35, carbs: 28, fats: 24),
                imageName: "https://images.unsplash.com/photo-1558030006-450675393462?w=400",
                cookTime: 30,
                isFavorite: true,
                ingredients: ["pork chops", "apples", "green beans", "onion", "butter", "thyme", "apple cider"],
                instructions: ["Season and sear pork chops", "Make apple sauce", "Steam green beans", "Rest pork chops", "Serve together"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_15",
                name: "Pork Carnitas",
                calories: 520,
                detail: "Slow-cooked pork carnitas with Mexican rice and beans",
                nutrition: NutritionInfo(protein: 40, carbs: 35, fats: 26),
                imageName: "https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?w=400",
                cookTime: 180,
                isFavorite: false,
                ingredients: ["pork shoulder", "cumin", "chili powder", "lime", "rice", "black beans", "cilantro"],
                instructions: ["Season pork with spices", "Slow cook until tender", "Shred pork", "Prepare rice and beans", "Serve with lime"],
                category: "Dinner"
            ),
            
            // Shrimp variations
            FoodItem(
                id: "dinner_16",
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
                id: "dinner_17",
                name: "Coconut Shrimp",
                calories: 480,
                detail: "Crispy coconut-crusted shrimp with sweet chili sauce",
                nutrition: NutritionInfo(protein: 26, carbs: 42, fats: 22),
                imageName: "https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=400",
                cookTime: 25,
                isFavorite: false,
                ingredients: ["large shrimp", "coconut flakes", "panko breadcrumbs", "sweet chili sauce", "rice", "lime"],
                instructions: ["Coat shrimp in coconut", "Deep fry until golden", "Prepare sweet chili sauce", "Cook rice", "Serve with lime"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_18",
                name: "Shrimp Paella",
                calories: 450,
                detail: "Spanish paella with shrimp, saffron rice, and vegetables",
                nutrition: NutritionInfo(protein: 24, carbs: 55, fats: 14),
                imageName: "https://images.unsplash.com/photo-1534080564583-6be75777b70a?w=400",
                cookTime: 40,
                isFavorite: true,
                ingredients: ["shrimp", "arborio rice", "saffron", "bell peppers", "peas", "tomatoes", "garlic"],
                instructions: ["Sauté vegetables", "Add rice and saffron", "Pour in broth", "Add shrimp", "Simmer until tender"],
                category: "Dinner"
            ),
            
            // Stuffed Peppers variations
            FoodItem(
                id: "dinner_19",
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
            ),
            FoodItem(
                id: "dinner_20",
                name: "Mediterranean Stuffed Peppers",
                calories: 380,
                detail: "Peppers stuffed with quinoa, feta cheese, and Mediterranean herbs",
                nutrition: NutritionInfo(protein: 18, carbs: 42, fats: 16),
                imageName: "https://images.unsplash.com/photo-1572441713132-51c75654db73?w=400",
                cookTime: 45,
                isFavorite: true,
                ingredients: ["bell peppers", "quinoa", "feta cheese", "olives", "sun-dried tomatoes", "oregano", "pine nuts"],
                instructions: ["Cook quinoa", "Mix with Mediterranean ingredients", "Stuff peppers", "Bake with feta on top", "Garnish with herbs"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_21",
                name: "Mexican Stuffed Peppers",
                calories: 400,
                detail: "Spicy peppers filled with black beans, corn, and Mexican cheese",
                nutrition: NutritionInfo(protein: 20, carbs: 48, fats: 14),
                imageName: "https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400",
                cookTime: 40,
                isFavorite: false,
                ingredients: ["poblano peppers", "black beans", "corn", "mexican cheese", "cumin", "chili powder", "cilantro"],
                instructions: ["Roast poblano peppers", "Mix beans with spices", "Stuff peppers", "Top with cheese", "Bake until melted"],
                category: "Dinner"
            ),
            
            // Fish variations
            FoodItem(
                id: "dinner_22",
                name: "Baked Cod",
                calories: 320,
                detail: "Herb-crusted cod with lemon and roasted vegetables",
                nutrition: NutritionInfo(protein: 35, carbs: 18, fats: 12),
                imageName: "https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["cod fillet", "herbs", "lemon", "zucchini", "cherry tomatoes", "olive oil", "garlic"],
                instructions: ["Season cod with herbs", "Arrange vegetables", "Drizzle with olive oil", "Bake together", "Serve with lemon"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_23",
                name: "Fish Tacos",
                calories: 380,
                detail: "Grilled fish tacos with cabbage slaw and lime crema",
                nutrition: NutritionInfo(protein: 28, carbs: 32, fats: 16),
                imageName: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["white fish", "corn tortillas", "cabbage", "lime", "sour cream", "cilantro", "avocado"],
                instructions: ["Grill seasoned fish", "Make cabbage slaw", "Prepare lime crema", "Warm tortillas", "Assemble tacos"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_24",
                name: "Tuna Steaks",
                calories: 480,
                detail: "Seared tuna steaks with sesame crust and Asian vegetables",
                nutrition: NutritionInfo(protein: 42, carbs: 24, fats: 24),
                imageName: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["tuna steaks", "sesame seeds", "bok choy", "shiitake mushrooms", "soy sauce", "ginger", "rice"],
                instructions: ["Coat tuna with sesame", "Sear tuna briefly", "Stir-fry vegetables", "Cook rice", "Slice tuna and serve"],
                category: "Dinner"
            ),
            
            // Pasta variations
            FoodItem(
                id: "dinner_25",
                name: "Spaghetti Carbonara",
                calories: 580,
                detail: "Classic carbonara with eggs, bacon, and parmesan cheese",
                nutrition: NutritionInfo(protein: 28, carbs: 52, fats: 28),
                imageName: "https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=400",
                cookTime: 20,
                isFavorite: true,
                ingredients: ["spaghetti", "eggs", "bacon", "parmesan cheese", "black pepper", "garlic", "olive oil"],
                instructions: ["Cook spaghetti", "Crisp bacon", "Beat eggs with cheese", "Toss hot pasta with egg mixture", "Serve immediately"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_26",
                name: "Penne Arrabbiata",
                calories: 420,
                detail: "Spicy penne pasta with tomatoes, garlic, and red pepper flakes",
                nutrition: NutritionInfo(protein: 14, carbs: 65, fats: 12),
                imageName: "https://images.unsplash.com/photo-1621852004158-f3bc188ace2d?w=400",
                cookTime: 25,
                isFavorite: false,
                ingredients: ["penne pasta", "tomatoes", "garlic", "red pepper flakes", "olive oil", "basil", "parmesan"],
                instructions: ["Cook penne pasta", "Sauté garlic and chili", "Add tomatoes", "Toss with pasta", "Garnish with basil"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_27",
                name: "Mushroom Risotto",
                calories: 460,
                detail: "Creamy mushroom risotto with white wine and parmesan",
                nutrition: NutritionInfo(protein: 16, carbs: 58, fats: 18),
                imageName: "https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=400",
                cookTime: 35,
                isFavorite: true,
                ingredients: ["arborio rice", "mixed mushrooms", "white wine", "vegetable broth", "parmesan", "onion", "butter"],
                instructions: ["Sauté mushrooms", "Toast rice with onion", "Add wine and broth gradually", "Stir constantly", "Finish with cheese"],
                category: "Dinner"
            ),
            
            // Steak variations
            FoodItem(
                id: "dinner_28",
                name: "Grilled Ribeye",
                calories: 650,
                detail: "Perfectly grilled ribeye steak with garlic mashed potatoes",
                nutrition: NutritionInfo(protein: 48, carbs: 28, fats: 38),
                imageName: "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400",
                cookTime: 20,
                isFavorite: true,
                ingredients: ["ribeye steak", "potatoes", "garlic", "butter", "rosemary", "salt", "pepper"],
                instructions: ["Season steak", "Grill to desired doneness", "Make garlic mashed potatoes", "Rest steak", "Serve together"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_29",
                name: "Filet Mignon",
                calories: 580,
                detail: "Tender filet mignon with red wine reduction and asparagus",
                nutrition: NutritionInfo(protein: 45, carbs: 12, fats: 32),
                imageName: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400",
                cookTime: 25,
                isFavorite: false,
                ingredients: ["filet mignon", "red wine", "asparagus", "shallots", "butter", "thyme", "beef stock"],
                instructions: ["Sear filet mignon", "Make wine reduction", "Roast asparagus", "Rest meat", "Serve with sauce"],
                category: "Dinner"
            ),
            FoodItem(
                id: "dinner_30",
                name: "Steak Fajitas",
                calories: 520,
                detail: "Sizzling steak fajitas with peppers, onions, and tortillas",
                nutrition: NutritionInfo(protein: 38, carbs: 35, fats: 24),
                imageName: "https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?w=400",
                cookTime: 30,
                isFavorite: true,
                ingredients: ["flank steak", "bell peppers", "onions", "flour tortillas", "lime", "cumin", "chili powder"],
                instructions: ["Marinate steak", "Grill steak and vegetables", "Slice steak thinly", "Warm tortillas", "Serve with toppings"],
                category: "Dinner"
            )
        ]
        
        // SNACK MEALS (7)
        let snackMeals = [
            // Nuts variations
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
                name: "Honey Roasted Nuts",
                calories: 200,
                detail: "Sweet honey-roasted mixed nuts with cinnamon",
                nutrition: NutritionInfo(protein: 6, carbs: 12, fats: 16),
                imageName: "https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["mixed nuts", "honey", "cinnamon", "vanilla extract"],
                instructions: ["Roast nuts with honey", "Sprinkle with cinnamon", "Cool before serving"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_3",
                name: "Spicy Nuts",
                calories: 185,
                detail: "Spicy roasted nuts with chili powder and lime",
                nutrition: NutritionInfo(protein: 7, carbs: 9, fats: 15),
                imageName: "https://images.unsplash.com/photo-1608537879346-b59a5bb7d2b5?w=400",
                cookTime: 10,
                isFavorite: false,
                ingredients: ["mixed nuts", "chili powder", "lime zest", "cayenne pepper"],
                instructions: ["Toss nuts with spices", "Roast until crispy", "Add lime zest"],
                category: "Snacks"
            ),
            
            // Apple variations
            FoodItem(
                id: "snack_4",
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
                id: "snack_5",
                name: "Apple with Almond Butter",
                calories: 220,
                detail: "Crisp apple slices with creamy almond butter",
                nutrition: NutritionInfo(protein: 6, carbs: 25, fats: 14),
                imageName: "https://images.unsplash.com/photo-1570197788417-0e82375c9371?w=400",
                cookTime: 2,
                isFavorite: false,
                ingredients: ["1 medium apple", "2 tbsp almond butter", "cinnamon"],
                instructions: ["Slice apple thinly", "Sprinkle with cinnamon", "Serve with almond butter"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_6",
                name: "Caramel Apple Slices",
                calories: 180,
                detail: "Apple slices with homemade caramel dip",
                nutrition: NutritionInfo(protein: 2, carbs: 38, fats: 6),
                imageName: "https://images.unsplash.com/photo-1571854996937-0b6919f36b78?w=400",
                cookTime: 5,
                isFavorite: true,
                ingredients: ["1 medium apple", "caramel sauce", "chopped nuts", "sea salt"],
                instructions: ["Make caramel sauce", "Slice apple", "Dip in caramel", "Sprinkle with nuts"],
                category: "Snacks"
            ),
            
            // Yogurt variations
            FoodItem(
                id: "snack_7",
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
                id: "snack_8",
                name: "Berry Greek Yogurt",
                calories: 170,
                detail: "Greek yogurt topped with fresh mixed berries",
                nutrition: NutritionInfo(protein: 15, carbs: 22, fats: 4),
                imageName: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400",
                cookTime: 2,
                isFavorite: true,
                ingredients: ["1 cup Greek yogurt", "mixed berries", "mint leaves"],
                instructions: ["Add berries to yogurt", "Garnish with mint", "Serve chilled"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_9",
                name: "Granola Greek Yogurt",
                calories: 220,
                detail: "Greek yogurt layered with crunchy granola and fruit",
                nutrition: NutritionInfo(protein: 16, carbs: 28, fats: 8),
                imageName: "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400",
                cookTime: 3,
                isFavorite: false,
                ingredients: ["1 cup Greek yogurt", "granola", "banana", "honey"],
                instructions: ["Layer yogurt and granola", "Add banana slices", "Drizzle with honey"],
                category: "Snacks"
            ),
            
            // Hummus variations
            FoodItem(
                id: "snack_10",
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
                id: "snack_11",
                name: "Spicy Red Pepper Hummus",
                calories: 140,
                detail: "Roasted red pepper hummus with pita chips",
                nutrition: NutritionInfo(protein: 6, carbs: 18, fats: 7),
                imageName: "https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=400",
                cookTime: 3,
                isFavorite: true,
                ingredients: ["red pepper hummus", "pita chips", "paprika", "olive oil"],
                instructions: ["Arrange pita chips", "Serve with hummus", "Drizzle with olive oil"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_12",
                name: "Avocado Hummus",
                calories: 160,
                detail: "Creamy avocado hummus with tortilla chips",
                nutrition: NutritionInfo(protein: 5, carbs: 16, fats: 10),
                imageName: "https://images.unsplash.com/photo-1506368249639-73a05d6f6488?w=400",
                cookTime: 2,
                isFavorite: false,
                ingredients: ["avocado hummus", "tortilla chips", "lime", "cilantro"],
                instructions: ["Blend avocado with hummus", "Serve with chips", "Garnish with cilantro"],
                category: "Snacks"
            ),
            
            // Cheese variations
            FoodItem(
                id: "snack_13",
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
                id: "snack_14",
                name: "Caprese Skewers",
                calories: 180,
                detail: "Fresh mozzarella, tomato, and basil skewers",
                nutrition: NutritionInfo(protein: 12, carbs: 8, fats: 12),
                imageName: "https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=400",
                cookTime: 10,
                isFavorite: true,
                ingredients: ["mozzarella balls", "cherry tomatoes", "basil leaves", "balsamic glaze"],
                instructions: ["Thread ingredients on skewers", "Drizzle with balsamic", "Serve fresh"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_15",
                name: "Brie with Grapes",
                calories: 220,
                detail: "Creamy brie cheese with fresh grapes and walnuts",
                nutrition: NutritionInfo(protein: 9, carbs: 18, fats: 14),
                imageName: "https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400",
                cookTime: 2,
                isFavorite: false,
                ingredients: ["brie cheese", "grapes", "walnuts", "honey"],
                instructions: ["Slice brie cheese", "Arrange with grapes", "Add walnuts and honey"],
                category: "Snacks"
            ),
            
            // Trail Mix variations
            FoodItem(
                id: "snack_16",
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
                id: "snack_17",
                name: "Tropical Trail Mix",
                calories: 210,
                detail: "Exotic trail mix with coconut, pineapple, and macadamias",
                nutrition: NutritionInfo(protein: 6, carbs: 22, fats: 14),
                imageName: "https://images.unsplash.com/photo-1608537879346-b59a5bb7d2b5?w=400",
                cookTime: 2,
                isFavorite: true,
                ingredients: ["macadamia nuts", "coconut flakes", "dried pineapple", "cashews"],
                instructions: ["Combine tropical ingredients", "Mix well", "Store in container"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_18",
                name: "Protein Trail Mix",
                calories: 240,
                detail: "High-protein mix with seeds, nuts, and beef jerky",
                nutrition: NutritionInfo(protein: 14, carbs: 12, fats: 16),
                imageName: "https://images.unsplash.com/photo-1599599810694-57a2ca21cd05?w=400",
                cookTime: 3,
                isFavorite: false,
                ingredients: ["pumpkin seeds", "beef jerky pieces", "almonds", "sunflower seeds"],
                instructions: ["Chop jerky into pieces", "Mix with nuts and seeds", "Store properly"],
                category: "Snacks"
            ),
            
            // Smoothie variations
            FoodItem(
                id: "snack_19",
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
            ),
            FoodItem(
                id: "snack_20",
                name: "Berry Smoothie",
                calories: 140,
                detail: "Antioxidant-rich mixed berry smoothie",
                nutrition: NutritionInfo(protein: 6, carbs: 28, fats: 2),
                imageName: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400",
                cookTime: 3,
                isFavorite: true,
                ingredients: ["mixed berries", "Greek yogurt", "almond milk", "honey"],
                instructions: ["Blend berries with yogurt", "Add milk and honey", "Blend until smooth"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_21",
                name: "Green Smoothie",
                calories: 120,
                detail: "Healthy green smoothie with spinach and apple",
                nutrition: NutritionInfo(protein: 4, carbs: 24, fats: 2),
                imageName: "https://images.unsplash.com/photo-1570197788417-0e82375c9371?w=400",
                cookTime: 4,
                isFavorite: false,
                ingredients: ["spinach", "green apple", "banana", "coconut water", "lime"],
                instructions: ["Blend spinach with apple", "Add banana and coconut water", "Squeeze lime"],
                category: "Snacks"
            ),
            
            // Chips variations
            FoodItem(
                id: "snack_22",
                name: "Baked Sweet Potato Chips",
                calories: 130,
                detail: "Crispy baked sweet potato chips with sea salt",
                nutrition: NutritionInfo(protein: 2, carbs: 28, fats: 3),
                imageName: "https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=400",
                cookTime: 25,
                isFavorite: true,
                ingredients: ["sweet potatoes", "olive oil", "sea salt", "paprika"],
                instructions: ["Slice sweet potatoes thinly", "Toss with oil and salt", "Bake until crispy"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_23",
                name: "Kale Chips",
                calories: 80,
                detail: "Crispy kale chips with nutritional yeast",
                nutrition: NutritionInfo(protein: 4, carbs: 12, fats: 3),
                imageName: "https://images.unsplash.com/photo-1506368249639-73a05d6f6488?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["kale leaves", "olive oil", "nutritional yeast", "garlic powder"],
                instructions: ["Remove kale stems", "Massage with oil", "Bake until crispy"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_24",
                name: "Zucchini Chips",
                calories: 100,
                detail: "Light and crispy baked zucchini chips",
                nutrition: NutritionInfo(protein: 3, carbs: 16, fats: 4),
                imageName: "https://images.unsplash.com/photo-1571854996937-0b6919f36b78?w=400",
                cookTime: 30,
                isFavorite: true,
                ingredients: ["zucchini", "parmesan cheese", "breadcrumbs", "herbs"],
                instructions: ["Slice zucchini rounds", "Coat with cheese and breadcrumbs", "Bake until golden"],
                category: "Snacks"
            ),
            
            // Energy balls variations
            FoodItem(
                id: "snack_25",
                name: "Peanut Butter Energy Balls",
                calories: 180,
                detail: "No-bake energy balls with peanut butter and oats",
                nutrition: NutritionInfo(protein: 8, carbs: 16, fats: 10),
                imageName: "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["rolled oats", "peanut butter", "honey", "chia seeds", "vanilla"],
                instructions: ["Mix all ingredients", "Roll into balls", "Chill until firm"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_26",
                name: "Coconut Date Balls",
                calories: 160,
                detail: "Sweet coconut and date energy balls",
                nutrition: NutritionInfo(protein: 4, carbs: 22, fats: 8),
                imageName: "https://images.unsplash.com/photo-1608537879346-b59a5bb7d2b5?w=400",
                cookTime: 20,
                isFavorite: false,
                ingredients: ["dates", "coconut flakes", "almonds", "vanilla extract"],
                instructions: ["Process dates until smooth", "Add coconut and almonds", "Form into balls"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_27",
                name: "Chocolate Protein Balls",
                calories: 200,
                detail: "Rich chocolate protein energy balls",
                nutrition: NutritionInfo(protein: 12, carbs: 18, fats: 8),
                imageName: "https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=400",
                cookTime: 10,
                isFavorite: true,
                ingredients: ["protein powder", "cocoa powder", "almond butter", "honey"],
                instructions: ["Mix dry ingredients", "Add wet ingredients", "Roll and chill"],
                category: "Snacks"
            ),
            
            // Popcorn variations
            FoodItem(
                id: "snack_28",
                name: "Air-Popped Popcorn",
                calories: 110,
                detail: "Light and fluffy air-popped popcorn with herbs",
                nutrition: NutritionInfo(protein: 4, carbs: 22, fats: 2),
                imageName: "https://images.unsplash.com/photo-1578849278619-e73505e9610f?w=400",
                cookTime: 5,
                isFavorite: false,
                ingredients: ["popcorn kernels", "nutritional yeast", "herbs", "sea salt"],
                instructions: ["Pop kernels in air popper", "Season with yeast and herbs", "Toss well"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_29",
                name: "Caramel Popcorn",
                calories: 150,
                detail: "Sweet and crunchy caramel-coated popcorn",
                nutrition: NutritionInfo(protein: 2, carbs: 30, fats: 4),
                imageName: "https://images.unsplash.com/photo-1559561853-08451507cbe7?w=400",
                cookTime: 15,
                isFavorite: true,
                ingredients: ["popped popcorn", "caramel sauce", "butter", "vanilla"],
                instructions: ["Make caramel sauce", "Toss with popcorn", "Spread to cool"],
                category: "Snacks"
            ),
            FoodItem(
                id: "snack_30",
                name: "Spicy Cheese Popcorn",
                calories: 130,
                detail: "Cheesy popcorn with a spicy kick",
                nutrition: NutritionInfo(protein: 5, carbs: 18, fats: 5),
                imageName: "https://images.unsplash.com/photo-1578849278619-e73505e9610f?w=400",
                cookTime: 8,
                isFavorite: false,
                ingredients: ["popped popcorn", "cheese powder", "chili powder", "lime zest"],
                instructions: ["Toss popcorn with cheese powder", "Add spices", "Mix with lime zest"],
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
        let collectionRef = db.collection("recipesNewFood")

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
