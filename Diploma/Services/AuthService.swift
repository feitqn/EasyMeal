import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import MessageUI
import Combine
import FirebaseFunctions
import CoreData
import Network

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: CDUser?
    @Published var isAuthenticated: Bool = false
    @Published var verificationCode: String?
    @Published var isCodeSent: Bool = false
    @Published var verificationEmail: String = ""
    @Published var isOnboardingCompleted: Bool = false
    @Published var tempUserData: (username: String, password: String)?
    @Published var isLoading: Bool = false
    @Published var networkError: AuthError?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let keychain = KeychainService.shared
    private let settings = SettingsService.shared
    
    init() {
        // Убираем setupNetworkMonitoring
    }
    
    // Генерация 6-значного кода
    private func generateVerificationCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }
    
    // Отправка кода верификации на email
    func sendVerificationCode(email: String, username: String, password: String) async throws {
        isLoading = true
        
        do {
            let code = generateVerificationCode()
            tempUserData = (username: username, password: password)
            
            let verificationData: [String: Any] = [
                "email": email,
                "code": code,
                "createdAt": FieldValue.serverTimestamp(),
                "isUsed": false
            ]
            
            // Сначала создаем пользователя
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Затем сохраняем код верификации
            try await db.collection("verificationCodes").document(email).setData(verificationData)
            
            // Отправляем email
            try await sendEmailViaCloudFunction(to: email, code: code)
            
            await MainActor.run {
                self.verificationEmail = email
                self.isCodeSent = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func retryOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        let maxAttempts = 3
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                if attempt > 1 {
                    // Экспоненциальная задержка перед повторной попыткой
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt - 1)) * 1_000_000_000))
                }
                return try await operation()
            } catch {
                lastError = error
                print("Попытка \(attempt) из \(maxAttempts) не удалась: \(error.localizedDescription)")
                if attempt == maxAttempts {
                    throw error
                }
            }
        }
        
        throw lastError ?? AuthError.unknown
    }
    
    private func sendEmailViaCloudFunction(to email: String, code: String) async throws {
        let functions = Functions.functions()
        let data: [String: Any] = [
            "email": email,
            "code": code,
            "type": "verification"
        ]
        
        _ = try await functions.httpsCallable("sendVerificationEmail").call(data)
    }
    
    // Проверка кода верификации
    func verifyCode(_ code: String) async throws {
        let document = try await db.collection("verificationCodes").document(verificationEmail).getDocument()
        
        guard let data = document.data(),
              let savedCode = data["code"] as? String,
              savedCode == code else {
            throw AuthError.invalidCode
        }
        
        // Обновляем статус кода
        try await db.collection("verificationCodes").document(verificationEmail).updateData([
            "isUsed": true
        ])
        
        // Устанавливаем флаги
        await MainActor.run {
            self.isCodeSent = false
            self.verificationCode = nil
            self.isAuthenticated = true
        }
    }
    
    // Вход через Google
    func signInWithGoogle() async throws {
        print("Начало входа через Google")
        
        isLoading = true
        networkError = nil
        
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                print("Ошибка: не найден clientID")
                throw AuthError.configurationError
            }
            
            print("Настройка конфигурации Google Sign In")
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            print("Получение rootViewController")
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("Ошибка: не найден rootViewController")
                throw AuthError.presentationError
            }
            
            print("Вызов Google Sign In")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            print("Получение токенов")
            guard let idToken = result.user.idToken?.tokenString else {
                print("Ошибка: не получен idToken")
                throw AuthError.invalidToken
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            print("Аутентификация в Firebase")
            let authResult = try await Auth.auth().signIn(with: credential)
            
            print("Сохранение пользователя")
            try await saveUserToDatabase(authResult.user)
            
            await MainActor.run {
                self.isAuthenticated = true
                self.networkError = nil
                self.isLoading = false
            }
            
            print("Вход через Google успешно завершен")
        } catch let error as NSError {
            print("Ошибка входа через Google: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.isAuthenticated = false
                
                switch error.domain {
                case "com.google.GIDSignIn":
                    switch error.code {
                    case -5: // Canceled
                        self.networkError = .userCancelled
                    case -2: // No keychain
                        self.networkError = .notAuthenticated
                    default:
                        self.networkError = .googleSignInError
                    }
                case AuthErrorDomain:
                    self.networkError = .firebaseAuthError
                default:
                    self.networkError = .unknown
                }
            }
            throw self.networkError ?? .unknown
        }
    }
    
    // Регистрация нового пользователя
    func register(username: String, email: String, password: String) async throws {
        isLoading = true
        
        do {
            // Создаем пользователя в Firebase Auth
            let result = try await auth.createUser(withEmail: email, password: password)
            let userId = result.user.uid
            
            // Создаем документ пользователя в Firestore
            let userData: [String: Any] = [
                "id": userId,
                "username": username,
                "email": email,
                "createdAt": FieldValue.serverTimestamp(),
                "isOnboardingCompleted": false
            ]
            
            try await db.collection("users").document(userId).setData(userData)
            
            // Сохраняем токен
            if let token = try? await result.user.getIDToken() {
                saveToken(token, for: userId)
            }
            
            // Обновляем состояние
            await MainActor.run {
                self.isAuthenticated = true
                self.isLoading = false
                
                // Сохраняем в Core Data
                let context = CoreDataStack.shared.viewContext
                let user = CDUser(context: context)
                user.id = userId
                user.username = username
                user.email = email
                user.createdAt = Date()
                user.isOnboardingCompleted = false
                
                try? context.save()
                self.currentUser = user
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        }
    }
    
    // Сохранение данных пользователя
    func saveUserData(_ user: CDUser) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await saveUser(id: user.id, username: user.username, email: user.email, userData: data)
    }
    
    // Загрузка данных пользователя
    func loadUserData() async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else {
            throw AuthError.unknown
        }
        
        try await saveUser(
            id: userId,
            username: data["username"] as? String ?? "",
            email: data["email"] as? String ?? "",
            userData: data
        )
        
        await MainActor.run {
            self.isAuthenticated = true
        }
    }
    
    // Обновление данных пользователя после онбординга
    func updateUserAfterOnboarding(age: Int, weight: Double, height: Double, goal: Goal) async throws {
        guard let user = currentUser else {
            throw AuthError.userNotFound
        }
        
        let context = CoreDataStack.shared.viewContext
        
        // Обновляем данные в Core Data
        user.age = Int16(age)
        user.weight = weight
        user.height = height
        user.goalRawValue = goal.rawValue
        user.dailyCalorieTarget = Int32(calculateDailyCalorieTarget(age: age, weight: weight, height: height, goal: goal))
        user.isOnboardingCompleted = true
        
        try context.save()
        
        // Обновляем данные в Firestore
        let userData: [String: Any] = [
            "age": age,
            "weight": weight,
            "height": height,
            "goal": goal.rawValue,
            "dailyCalorieTarget": user.dailyCalorieTarget,
            "isOnboardingCompleted": true
        ]
        
        try await db.collection("users").document(user.id).updateData(userData)
        
        await MainActor.run {
            self.currentUser = user
            self.isOnboardingCompleted = true
        }
    }
    
    private func calculateDailyCalorieTarget(age: Int, weight: Double, height: Double, goal: Goal) -> Int {
        // Базовый расчет калорий (формула Харриса-Бенедикта)
        let bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        
        switch goal {
        case .loss: return Int(bmr * 0.8)
        case .gain: return Int(bmr * 1.2)
        case .maintenance: return Int(bmr)
        }
    }
    
    // Вход пользователя с идентификатором (email или username)
    func login(identifier: String, password: String) async throws {
        print("Попытка входа с идентификатором: \(identifier)")
        
        if identifier.contains("@") {
            print("Идентификатор распознан как email")
            try await self.login(email: identifier, password: password)
            return
        }
        
        print("Идентификатор распознан как username, ищем соответствующий email")
        let querySnapshot = try await self.db.collection("users")
            .whereField("username", isEqualTo: identifier)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first,
              let email = document.data()["email"] as? String else {
            print("Пользователь с таким username не найден")
            throw AuthError.userNotFound
        }
        
        print("Найден email для username: \(email)")
        try await self.login(email: email, password: password)
    }
    
    // Вход пользователя по email
    private func login(email: String, password: String) async throws {
        print("Вход по email: \(email)")
        let result = try await self.auth.signIn(withEmail: email, password: password)
        let userId = result.user.uid
        
        let document = try await self.db.collection("users").document(userId).getDocument()
        guard let data = document.data() else {
            print("Не удалось получить данные пользователя")
            throw AuthError.unknown
        }
        
        await MainActor.run {
            self.saveUserToCoreData(data)
            // Проверяем, заполнены ли данные пользователя
            if let user = self.currentUser {
                self.isOnboardingCompleted = user.isOnboardingCompleted
            }
            self.isAuthenticated = true
        }
    }
    
    // Сброс пароля
    func sendPasswordResetEmail(email: String) -> AnyPublisher<Void, AuthError> {
        return Future { [weak self] promise in
            self?.auth.sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    print("Password reset error: \(error.localizedDescription)")
                    promise(.failure(.invalidEmail))
                    return
                }
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    // Выход из аккаунта
    func signOut() async throws {
        try auth.signOut()
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    // Проверка текущего состояния аутентификации
    func checkAuthStatus() async throws {
        if let user = auth.currentUser {
            let document = try await db.collection("users").document(user.uid).getDocument()
            guard let data = document.data() else {
                throw AuthError.unknown
            }
            saveUserToCoreData(data)
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
        }
    }
    
    func signInWithApple() -> AnyPublisher<Void, AuthError> {
        return Future { promise in
            // Реализация входа через Apple
        }.eraseToAnyPublisher()
    }
    
    func signInWithFacebook() -> AnyPublisher<Void, AuthError> {
        return Future { promise in
            // Реализация входа через Facebook
        }.eraseToAnyPublisher()
    }
    
    // Отправка кода верификации на телефон
    func sendVerificationCode(phoneNumber: String) async throws {
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            DispatchQueue.main.async {
                self.verificationCode = verificationID
                self.isCodeSent = true
            }
        } catch {
            print("Error sending code: \(error.localizedDescription)")
            throw AuthError.unknown
        }
    }
    
    // Проверка кода верификации телефона
    func verifyPhoneCode(_ code: String) async throws {
        guard let verificationID = verificationCode else {
            throw AuthError.invalidCode
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        let result = try await auth.signIn(with: credential)
        let userId = result.user.uid
        
        let userData: [String: Any] = [
            "phoneNumber": result.user.phoneNumber ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(userId).setData(userData, merge: true)
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    // Обновленный метод для работы с результатом верификации
    private func handleVerificationResult(_ result: AuthDataResult?, _ error: Error?) -> Result<String, AuthError> {
        if let error = error {
            print("Verification error: \(error.localizedDescription)")
            return .failure(.unknown)
        }
        
        guard let userId = result?.user.uid else {
            return .failure(.unknown)
        }
        
        return .success(userId)
    }
    
    private func saveUserToCoreData(_ userData: [String: Any]) {
        let context = CoreDataStack.shared.viewContext
        
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userData["id"] as? String ?? "")
        
        do {
            let existingUsers = try context.fetch(fetchRequest)
            let user: CDUser
            
            if let existingUser = existingUsers.first {
                user = existingUser
            } else {
                user = CDUser(context: context)
                user.id = userData["id"] as? String ?? UUID().uuidString
            }
            
            // Обновляем данные пользователя
            user.username = userData["username"] as? String ?? ""
            user.email = userData["email"] as? String ?? ""
            user.createdAt = (userData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            user.age = Int16(userData["age"] as? Int ?? 0)
            user.weight = userData["weight"] as? Double ?? 0.0
            user.height = userData["height"] as? Double ?? 0.0
            user.goalRawValue = userData["goal"] as? String ?? Goal.maintenance.rawValue
            user.dailyCalorieTarget = Int32(userData["dailyCalorieTarget"] as? Int ?? 0)
            user.waterTarget = Int32(userData["waterTarget"] as? Int ?? 0)
            user.isOnboardingCompleted = userData["isOnboardingCompleted"] as? Bool ?? false
            user.lastSyncTimestamp = (userData["lastSyncTimestamp"] as? Timestamp)?.dateValue()
            user.gender = userData["gender"] as? String ?? ""
            user.birthday = (userData["birthday"] as? Timestamp)?.dateValue()
            user.targetWeight = userData["targetWeight"] as? Double ?? 0.0
            user.currentWeight = userData["currentWeight"] as? Double ?? 0.0
            
            try context.save()
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isOnboardingCompleted = user.isOnboardingCompleted
            }
        } catch {
            print("Error saving user to Core Data: \(error)")
        }
    }
    
    // Сохранение токена в Keychain
    private func saveToken(_ token: String, for userId: String) {
        try? keychain.save(token, for: userId)
    }
    
    // Синхронизация данных
    func syncUserData() async throws {
        guard let userId = auth.currentUser?.uid else { return }
        
        // 1. Получаем данные из Firestore
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else { return }
        
        // 2. Обновляем CoreData
        saveUserToCoreData(data)
        
        // 3. Обновляем timestamp синхронизации
        try await db.collection("users").document(userId).updateData([
            "lastSyncTimestamp": Date()
        ])
    }
    
    @MainActor
    private func saveUser(id: String, username: String, email: String, userData: [String: Any]) async throws {
        let context = CoreDataStack.shared.viewContext
        
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        let user: CDUser
        
        if let existingUser = try? context.fetch(fetchRequest).first {
            user = existingUser
        } else {
            user = CDUser(context: context)
            user.id = id
        }
        
        // Обновляем данные пользователя
        user.username = username
        user.email = email
        user.createdAt = (userData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        user.age = Int16(userData["age"] as? Int ?? 0)
        user.weight = userData["weight"] as? Double ?? 0.0
        user.height = userData["height"] as? Double ?? 0.0
        user.goalRawValue = userData["goal"] as? String ?? Goal.maintenance.rawValue
        user.dailyCalorieTarget = Int32(userData["dailyCalorieTarget"] as? Int ?? 0)
        user.waterTarget = Int32(userData["waterTarget"] as? Int ?? 0)
        user.isOnboardingCompleted = userData["isOnboardingCompleted"] as? Bool ?? false
        user.lastSyncTimestamp = (userData["lastSyncTimestamp"] as? Timestamp)?.dateValue()
        user.gender = userData["gender"] as? String ?? ""
        user.birthday = (userData["birthday"] as? Timestamp)?.dateValue()
        user.targetWeight = userData["targetWeight"] as? Double ?? 0.0
        user.currentWeight = userData["currentWeight"] as? Double ?? 0.0
        
        try context.save()
        
        // Обновляем данные в Firestore с учетом типов данных
        var firestoreData = userData
        firestoreData["createdAt"] = FieldValue.serverTimestamp()
        firestoreData["lastSyncTimestamp"] = FieldValue.serverTimestamp()
        if let birthday = user.birthday {
            firestoreData["birthday"] = Timestamp(date: birthday)
        }
        
        try await Firestore.firestore().collection("users").document(id).setData(firestoreData, merge: true)
        
        self.currentUser = user
    }
    
    @MainActor
    private func saveUserToDatabase(_ user: FirebaseAuth.User) throws {
        let userData: [String: Any] = [
            "id": user.uid,
            "username": user.displayName ?? "User",
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "age": 0,
            "weight": 0.0,
            "height": 0.0,
            "goal": Goal.maintenance.rawValue,
            "dailyCalorieTarget": 2000,
            "waterTarget": 2000,
            "isOnboardingCompleted": false,
            "gender": "",
            "targetWeight": 0.0,
            "currentWeight": 0.0
        ]
        
        Task {
            try await saveUser(
                id: user.uid,
                username: user.displayName ?? "User",
                email: user.email ?? "",
                userData: userData
            )
            
            self.isAuthenticated = true
            self.isOnboardingCompleted = false
        }
    }
    
    // Удаление всех пользователей
} 
