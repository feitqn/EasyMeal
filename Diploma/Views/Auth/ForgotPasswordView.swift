import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showVerification = false
    
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
                Text("Forgot Password?")
                    .font(.title)
                    .fontWeight(.bold)
                Text("No problem. Enter your email to recover it.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Email поле
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.gray)
                TextField("E-mail", text: $email)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Кнопка отправки кода
            Button {
                sendResetCode()
            } label: {
                Text("Send Code")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Remember password
            HStack {
                Text("Remember password?")
                    .foregroundColor(.gray)
                Button("Login Now") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showVerification) {
            VerificationView(email: email)
        }
    }
    
    private func sendResetCode() {
        authService.sendPasswordResetEmail(email: email)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            } receiveValue: { _ in
                showVerification = true
            }
            .cancel()
    }
} 