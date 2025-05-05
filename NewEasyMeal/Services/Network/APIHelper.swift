import Foundation
import FirebaseAuth
import FirebaseFirestore

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
            
            guard var meals = data["meals"] as? [[String: Any]], var remainingCalories = data["remainingCalories"] as? Int else {
                return
            }
            
            guard let index = meals.firstIndex(where: { $0["name"] as? String == type.rawValue.lowercased() }) else {
                return
            }
            
            var updatedFields = ["calories": index]
            
            for (key, value) in updatedFields {
                if let intValue = meals[index][key] as? Int {
                    meals[index][key] = intValue + food.calories
                    remainingCalories = remainingCalories - food.calories
                }
            }

            Task {
                do {
                    try await self.updateMealsAsync(docRef: docRef, meals: meals, remainingCalories: remainingCalories)
                    NotificationCenter.default.post(name: .shouldFetchHomeData, object: nil)
                } catch {
                    print("Ошибка обновления: \(error)")
                }
            }
        }
    }
    
    func updateMealsAsync(docRef: DocumentReference, meals: [[String : Any]], remainingCalories: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            docRef.updateData(["meals": meals, "remainingCalories": remainingCalories]) { error in
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
}
