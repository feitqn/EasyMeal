import SwiftUI

struct PasswordChangedView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Иконка успеха
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            // Текст успеха
            Text("Password Changed!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your password has been changed successfully")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Кнопка возврата к логину
            Button(action: {
                dismiss()
            }) {
                Text("Back to Login")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
} 