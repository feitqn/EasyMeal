import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showVerification = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showNetworkAlert = false
    @State private var retryAction: (() -> Void)?
    
    var body: some View {
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
                Text("Create an account")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Connect with your friends today!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Форма регистрации
            VStack(spacing: 16) {
                // Email поле
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Username поле
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Password поле
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Confirm Password поле
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    if isConfirmPasswordVisible {
                        TextField("Confirm Password", text: $confirmPassword)
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                    }
                    Button(action: {
                        isConfirmPasswordVisible.toggle()
                    }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Register кнопка
            Button {
                signUp()
            } label: {
                Text("Register")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(isValidForm ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .disabled(!isValidForm)
            
            Spacer()
            
            // Вход
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                Button("Login") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding(.bottom)
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Нет подключения", isPresented: $showNetworkAlert) {
            Button("Повторить") {
                retryAction?()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showVerification) {
            VerificationView(email: email)
        }
    }
    
    private func signUp() {
        guard isValidForm else {
            errorMessage = "Пожалуйста, проверьте правильность заполнения всех полей"
            showError = true
            return
        }
        
        Task {
            do {
                try await authService.sendVerificationCode(email: email, username: username, password: password)
                showVerification = true
            } catch {
                errorMessage = "Произошла ошибка при регистрации: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private var isValidForm: Bool {
        let emailIsValid = !email.isEmpty && email.contains("@") && email.contains(".")
        let passwordIsValid = !password.isEmpty && password.count >= 6
        let passwordsMatch = password == confirmPassword
        let usernameIsValid = !username.isEmpty && username.count >= 3
        
        print("Валидация формы:")
        print("Email (\(email)): \(emailIsValid)")
        print("Password: \(passwordIsValid)")
        print("Passwords match: \(passwordsMatch)")
        print("Username (\(username)): \(usernameIsValid)")
        
        return emailIsValid && passwordIsValid && passwordsMatch && usernameIsValid
    }
} 