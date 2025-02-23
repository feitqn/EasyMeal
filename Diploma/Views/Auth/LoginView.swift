import SwiftUI
import Combine

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showMainApp = false
    @State private var showRegistration = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Кнопка назад
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Заголовок
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back!")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Sign in to continue")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Форма входа
                    VStack(spacing: 16) {
                        // Email
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            TextField("Email или Username", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Password
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    // Login Button
                    Button(action: login) {
                        ZStack {
                            Text("Login")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    }
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isLoading)
                    
                    // Разделитель
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("or Login with")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    
                    // Социальные кнопки
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            SocialLoginButton(
                                action: handleGoogleSignIn,
                                image: "google",
                                text: "Google"
                            )
                            
                            SocialLoginButton(
                                action: {},
                                systemImage: "apple.logo",
                                text: "Apple"
                            )
                        }
                    }
                    .padding()
                    
                    Spacer(minLength: 0)
                    
                    // Register Now
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        Button("Register") {
                            showRegistration = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegistration) {
                SignUpView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .alert("Error", isPresented: $showError) {
                if let suggestion = authService.networkError?.recoverySuggestion {
                    Button(suggestion) {
                        handleErrorRecovery()
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showMainApp) {
                MainTabView()
            }
            .onChange(of: authService.isAuthenticated) { newValue in
                showMainApp = newValue
            }
            .onChange(of: authService.networkError) { error in
                if let error = error {
                    errorMessage = error.errorDescription ?? "Неизвестная ошибка"
                    showError = true
                }
            }
            .onChange(of: authService.isLoading) { newValue in
                isLoading = newValue
            }
        }
    }
    
    private func handleErrorRecovery() {
        guard let networkError = authService.networkError else { return }
        
        switch networkError {
        case .networkError(let reason):
            switch reason {
            case .noConnection:
                print("LoginView: Нет подключения к сети. Проверьте подключение и попробуйте снова.")
                // Здесь можно добавить показ сообщения о необходимости проверить подключение
            case .timeout:
                print("LoginView: Превышено время ожидания. Повторите попытку.")
                // Здесь можно добавить автоматическую повторную попытку
            case .other:
                print("LoginView: Проблема с сетью. Повторите попытку позже.")
            }
            
        case .serverError:
            print("LoginView: Ошибка сервера. Повторите попытку позже.")
            
        case .userCancelled:
            print("LoginView: Операция отменена пользователем.")
            
        case .notAuthenticated:
            print("LoginView: Требуется повторная авторизация.")
            
        case .googleSignInError:
            print("LoginView: Ошибка входа через Google. Попробуйте войти с помощью email.")
            
        case .firebaseAuthError:
            print("LoginView: Ошибка аутентификации Firebase. Проверьте данные и попробуйте снова.")
            
        default:
            print("LoginView: Неизвестная ошибка. Попробуйте позже.")
        }
        
        // Сбрасываем ошибку после обработки
        DispatchQueue.main.async {
            authService.networkError = nil
        }
    }
    
    private func login() {
        Task {
            do {
                isLoading = true
                try await authService.login(identifier: email, password: password)
                
                // После успешного входа проверяем, нужен ли онбординг
                if !authService.isOnboardingCompleted {
                    // Показываем онбординг
                    showMainApp = false
                    // Здесь можно добавить показ онбординга
                } else {
                    // Если онбординг пройден, показываем главный экран
                    showMainApp = true
                }
            } catch {
                if let authError = error as? AuthError {
                    errorMessage = authError.errorDescription ?? "Неизвестная ошибка"
                } else {
                    errorMessage = "Произошла ошибка при входе. Пожалуйста, попробуйте позже."
                }
                showError = true
            }
            isLoading = false
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            do {
                isLoading = true
                try await authService.signInWithGoogle()
                
                // После успешного входа проверяем, нужен ли онбординг
                if !authService.isOnboardingCompleted {
                    // Показываем онбординг
                    showMainApp = false
                    // Здесь можно добавить показ онбординга
                } else {
                    // Если онбординг пройден, показываем главный экран
                    showMainApp = true
                }
            } catch {
                if let authError = error as? AuthError {
                    errorMessage = authError.errorDescription ?? "Неизвестная ошибка"
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            }
            isLoading = false
        }
    }
}

struct SocialLoginButton: View {
    let action: () -> Void
    let systemImage: String?
    let image: String?
    let text: String
    
    init(action: @escaping () -> Void, systemImage: String? = nil, image: String? = nil, text: String) {
        self.action = action
        self.systemImage = systemImage
        self.image = image
        self.text = text
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else if let image = image {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                Text(text)
                    .font(.title3)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    LoginView()
} 