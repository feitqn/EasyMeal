import SwiftUI

struct CreateNewPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
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
                Text("Create New Password")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Your new password must be unique from those previously used.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            if !newPassword.isEmpty && newPassword != confirmPassword {
                Text("Required fields cannot be empty.")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Новый пароль
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    if isNewPasswordVisible {
                        TextField("New password", text: $newPassword)
                    } else {
                        SecureField("New password", text: $newPassword)
                    }
                    Button(action: {
                        isNewPasswordVisible.toggle()
                    }) {
                        Image(systemName: isNewPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    if isConfirmPasswordVisible {
                        TextField("Confirm password", text: $confirmPassword)
                    } else {
                        SecureField("Confirm password", text: $confirmPassword)
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
            
            // Кнопка сброса пароля
            Button {
                showSuccess = true
            } label: {
                Text("Reset Password")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(newPassword.isEmpty || newPassword != confirmPassword)
            
            Spacer()
        }
        .fullScreenCover(isPresented: $showSuccess) {
            PasswordChangedView()
        }
    }
} 