import SwiftUI

struct CodeVerificationView: View {
    @Binding var verificationCode: String
    let email: String
    let onVerify: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Verify your email")
                .font(.title)
                .fontWeight(.bold)
            
            Text("We've sent a verification code to:")
                .foregroundColor(.gray)
            Text(email)
                .fontWeight(.semibold)
            
            TextField("Enter verification code", text: $verificationCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button(action: onVerify) {
                Text("Verify")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .disabled(verificationCode.count != 6)
            .padding()
        }
    }
}

#Preview {
    CodeVerificationView(
        verificationCode: .constant(""),
        email: "test@example.com",
        onVerify: {}
    )
} 