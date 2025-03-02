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

class AuthService: ObservableObject {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west1")
    
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var networkError: Error?
    @Published var isOnboardingCompleted = false
    @Published var tempUserData: (username: String, email: String, password: String)?
    @Published var isLoading = false
    @Published var verificationCode: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        setupNetworkMonitoring()
        checkAuthState()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.networkError = nil
                } else {
                    self?.networkError = NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Нет подключения к интернету"])
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func checkAuthState() {
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.user = user
                
                if let user = user {
                    Task {
                        do {
                            let document = try await self?.db.collection("users").document(user.uid).getDocument()
                            self?.isOnboardingCompleted = document?.data()?["onboardingCompleted"] as? Bool ?? false
                        } catch {
                            print("Ошибка при проверке статуса онбординга: \(error)")
                        }
                    }
                } else {
                    self?.isOnboardingCompleted = false
                }
            }
        }
    }
    
    func login(identifier: String, password: String) async throws {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        defer { 
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        do {
            let result = try await auth.signIn(withEmail: identifier, password: password)
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
            }
        } catch {
            throw error
        }
    }
    
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка конфигурации Google Sign In"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let rootViewController = window.rootViewController else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить root view controller"])
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить ID token"])
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await auth.signIn(with: credential)
            DispatchQueue.main.async {
                self.user = authResult.user
                self.isAuthenticated = true
            }
        } catch {
            throw error
        }
    }
    
    func sendPasswordResetEmail(email: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            Task {
                do {
                    try await self?.auth.sendPasswordReset(withEmail: email)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signOut() async throws {
        do {
            try auth.signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            throw error
        }
    }
    
    func sendVerificationCode(email: String, username: String, password: String) async throws {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        defer { 
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        do {
            print("Проверка существующего email: \(email)")
            let methods = try await auth.fetchSignInMethods(forEmail: email)
            if !methods.isEmpty {
                throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Пользователь с таким email уже существует"])
            }
            
            print("Генерация кода верификации")
            let code = String(format: "%06d", Int.random(in: 0...999999))
            
            print("Сохранение временных данных")
            DispatchQueue.main.async {
                self.verificationCode = code
                self.tempUserData = (username: username, email: email, password: password)
            }
            
            print("Отправка кода через Cloud Functions")
            let data = [
                "email": email,
                "code": code,
                "username": username
            ] as [String : Any]
            
            do {
                let result = try await functions.httpsCallable("sendVerificationCode").call(data)
                print("Результат отправки кода: \(result.data ?? "нет данных")")
                
                if let resultDict = result.data as? [String: Any],
                   (resultDict["success"] as? Bool) == true {
                    print("Код успешно отправлен")
                } else {
                    print("Ошибка: неожиданный формат ответа")
                    throw NSError(
                        domain: "CloudFunctionsError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Ошибка при отправке кода верификации"]
                    )
                }
            } catch let functionsError as NSError {
                print("Ошибка Cloud Functions: \(functionsError)")
                if functionsError.domain == "com.google.firebase.functions" {
                    throw NSError(
                        domain: "AuthError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Сервис временно недоступен. Пожалуйста, попробуйте позже."]
                    )
                }
                throw functionsError
            }
        } catch {
            print("Ошибка при отправке кода: \(error.localizedDescription)")
            throw error
        }
    }
    
    func verifyCode(_ code: String) async throws -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        defer { 
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        print("Проверка временных данных пользователя")
        guard let tempData = tempUserData else {
            print("Ошибка: данные пользователя не найдены")
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Данные пользователя не найдены"])
        }
        
        print("Проверка кода верификации")
        print("Введенный код: \(code)")
        print("Сохраненный код: \(verificationCode ?? "не найден")")
        
        guard code == verificationCode else {
            print("Ошибка: неверный код верификации")
            return false
        }
        
        do {
            print("Создание пользователя в Firebase")
            let result = try await auth.createUser(withEmail: tempData.email, password: tempData.password)
            
            print("Создание документа пользователя в Firestore")
            try await db.collection("users").document(result.user.uid).setData([
                "username": tempData.username,
                "email": tempData.email,
                "createdAt": FieldValue.serverTimestamp(),
                "onboardingCompleted": false
            ])
            
            print("Пользователь успешно создан")
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
            }
            return true
        } catch {
            print("Ошибка при создании пользователя: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUserAfterOnboarding(age: Int, weight: Double, height: Double, goal: Goal) async throws {
        guard let user = user else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        let userData: [String: Any] = [
            "age": age,
            "weight": weight,
            "height": height,
            "goal": goal.rawValue,
            "onboardingCompleted": true
        ]
        
        try await db.collection("users").document(user.uid).setData(userData, merge: true)
        isOnboardingCompleted = true
    }
    
    func deleteAllUsers() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Получаем все документы пользователей из Firestore
            let snapshot = try await db.collection("users").getDocuments()
            
            // Удаляем каждый документ
            for document in snapshot.documents {
                try await db.collection("users").document(document.documentID).delete()
            }
            
            // Выходим из текущего аккаунта
            try await signOut()
            
            print("Все пользователи успешно удалены")
        } catch {
            throw error
        }
    }
    
    func deleteCurrentUser() async throws {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        defer { 
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard let user = user else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        do {
            // Удаляем документ пользователя из Firestore
            try await db.collection("users").document(user.uid).delete()
            
            // Удаляем пользователя из Firebase Auth
            try await user.delete()
            
            // Выходим из системы
            try await signOut()
            
            print("Пользователь успешно удален")
        } catch {
            throw error
        }
    }
} 
