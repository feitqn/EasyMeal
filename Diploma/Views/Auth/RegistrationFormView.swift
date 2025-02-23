import SwiftUI

struct RegistrationFormView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var username: String
    @Binding var email: String
    @Binding var password: String
    @Binding var isPasswordVisible: Bool
    @Binding var acceptedTerms: Bool
    let onRegister: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Кнопка назад
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Заголовок
            VStack(alignment: .leading, spacing: 8) {
                Text("Hello! Register to get")
                    .font(.title)
                    .fontWeight(.bold)
                Text("started!")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Форма регистрации
            VStack(spacing: 16) {
                // Username
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                    TextField("Username", text: $username)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Email
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    TextField("E-mail", text: $email)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Password
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
            }
            .padding(.horizontal)
            
            // Terms and Conditions
            Toggle(isOn: $acceptedTerms) {
                HStack {
                    Text("I accept the ")
                    Link("Terms of Service", destination: Constants.Links.termsOfService)
                        .foregroundColor(.blue)
                    Text(" and ")
                    Link("Privacy Policy", destination: Constants.Links.privacyPolicy)
                        .foregroundColor(.blue)
                }
                .font(.footnote)
            }
            .padding(.horizontal)
            
            // Register Button
            Button(action: onRegister) {
                Text("Register")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(!acceptedTerms)
            .opacity(acceptedTerms ? 1 : 0.6)
            
            Spacer()
            
            // Login Now
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                Button("Login Now") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    RegistrationFormView(
        username: .constant(""),
        email: .constant(""),
        password: .constant(""),
        isPasswordVisible: .constant(false),
        acceptedTerms: .constant(false),
        onRegister: {}
    )
} 