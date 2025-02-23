import SwiftUI

struct VerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    let email: String
    
    @State private var verificationCode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
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
                Text("Enter Verification Code")
                    .font(.title)
                    .fontWeight(.bold)
                Text("We have sent the code verification to your email address")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Код верификации
            VStack(spacing: 16) {
                TextField("Enter verification code", text: $verificationCode)
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
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify")
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
            .disabled(isLoading || verificationCode.count != 6)
            
            // Повторная отправка кода
            HStack {
                Text("Didn't receive code?")
                    .foregroundColor(.gray)
                Button("Resend") {
                    resendCode()
                }
                .foregroundColor(.blue)
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
        Task {
            do {
                try await authService.verifyCode(verificationCode)
                showSuccess = true
            } catch {
                errorMessage = "Неверный код верификации"
                showError = true
            }
        }
    }
    
    private func resendCode() {
        Task {
            do {
                if let tempData = authService.tempUserData {
                    try await authService.sendVerificationCode(
                        email: email,
                        username: tempData.username,
                        password: tempData.password
                    )
                }
            } catch {
                errorMessage = "Не удалось отправить код повторно"
                showError = true
            }
        }
    }
} 