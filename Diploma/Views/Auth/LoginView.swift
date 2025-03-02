import SwiftUI
import Combine

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
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
                    BackButton(dismiss: dismiss)
                    HeaderView()
                    LoginFormView(email: $email, password: $password)
                    ForgotPasswordButton(showForgotPassword: $showForgotPassword)
                    LoginButton(isLoading: isLoading, action: login)
                    DividerView()
                    SocialLoginButtons(handleGoogleSignIn: handleGoogleSignIn)
                    RegisterNowView(showRegistration: $showRegistration)
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
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showMainApp) {
                MainTabView()
            }
        }
    }
    
    private func login() {
        Task {
            do {
                isLoading = true
                try await authService.login(identifier: email, password: password)
                
                if !authService.isOnboardingCompleted {
                    showMainApp = false
                } else {
                    showMainApp = true
                }
            } catch {
                errorMessage = "Произошла ошибка при входе. Пожалуйста, попробуйте позже."
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
                
                if !authService.isOnboardingCompleted {
                    showMainApp = false
                } else {
                    showMainApp = true
                }
            } catch {
                errorMessage = "Ошибка входа через Google. Попробуйте позже."
                showError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Subviews

struct BackButton: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct HeaderView: View {
    var body: some View {
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
    }
}

struct LoginFormView: View {
    @Binding var email: String
    @Binding var password: String
    
    var body: some View {
        VStack(spacing: 16) {
            InputField(text: $email, 
                      icon: "envelope", 
                      placeholder: "Email или Username",
                      keyboardType: .emailAddress,
                      textContentType: .emailAddress)
            
            SecureInputField(text: $password,
                           icon: "lock",
                           placeholder: "Password")
        }
        .padding(.horizontal)
    }
}

struct InputField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SecureInputField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ForgotPasswordButton: View {
    @Binding var showForgotPassword: Bool
    
    var body: some View {
        HStack {
            Spacer()
            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }
}

struct LoginButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(12)
        }
        .disabled(isLoading)
        .padding(.horizontal)
    }
}

struct DividerView: View {
    var body: some View {
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
    }
}

struct SocialLoginButtons: View {
    let handleGoogleSignIn: () -> Void
    
    var body: some View {
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
        .padding()
    }
}

struct RegisterNowView: View {
    @Binding var showRegistration: Bool
    
    var body: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(.gray)
            Button("Register") {
                showRegistration = true
            }
            .foregroundColor(.blue)
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