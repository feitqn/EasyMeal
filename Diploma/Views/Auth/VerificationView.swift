import SwiftUI

struct VerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    let email: String
    
    @State private var verificationCode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
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
                Text("Введите код верификации")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Мы отправили код подтверждения на вашу почту")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Код верификации
            VStack(spacing: 16) {
                TextField("Введите код подтверждения", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Verify кнопка
            Button {
                verifyCode()
            } label: {
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Подтвердить")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .disabled(authService.isLoading || verificationCode.count != 6)
            
            // Повторная отправка кода
            HStack {
                Text("Не получили код?")
                    .foregroundColor(.gray)
                Button("Отправить повторно") {
                    resendCode()
                }
                .foregroundColor(.blue)
                .disabled(authService.isLoading)
            }
            
            Spacer()
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showSuccess) {
            RegistrationSuccessView()
        }
    }
    
    private func verifyCode() {
        guard !verificationCode.isEmpty else {
            errorMessage = "Пожалуйста, введите код верификации"
            showError = true
            return
        }
        
        Task {
            do {
                if try await authService.verifyCode(verificationCode) {
                    showSuccess = true
                } else {
                    errorMessage = "Неверный код верификации. Пожалуйста, проверьте код и попробуйте снова."
                    showError = true
                }
            } catch {
                if let nsError = error as NSError? {
                    switch nsError.domain {
                    case "AuthError":
                        errorMessage = nsError.localizedDescription
                    case "NetworkError":
                        errorMessage = "Проверьте подключение к интернету и попробуйте снова"
                    case "CloudFunctionsError":
                        errorMessage = "Ошибка сервера. Пожалуйста, попробуйте позже."
                    default:
                        errorMessage = "Произошла ошибка при проверке кода. Попробуйте позже."
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            }
        }
    }
    
    private func resendCode() {
        Task {
            if let tempData = authService.tempUserData {
                do {
                    try await authService.sendVerificationCode(
                        email: tempData.email,
                        username: tempData.username,
                        password: tempData.password
                    )
                    DispatchQueue.main.async {
                        self.errorMessage = "Новый код верификации отправлен на вашу почту"
                        self.showError = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        if let nsError = error as NSError? {
                            switch nsError.domain {
                            case "NetworkError":
                                self.errorMessage = "Проверьте подключение к интернету"
                            case "CloudFunctionsError":
                                self.errorMessage = "Ошибка при отправке кода. Попробуйте позже."
                            default:
                                self.errorMessage = nsError.localizedDescription
                            }
                        } else {
                            self.errorMessage = error.localizedDescription
                        }
                        self.showError = true
                    }
                }
            }
        }
    }
} 