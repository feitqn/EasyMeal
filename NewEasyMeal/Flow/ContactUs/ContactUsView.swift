import SwiftUI

struct ContactUsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // Back button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .gray.opacity(0.2), radius: 2)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Title
            Text("Contact Us")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Contact Options
            VStack(spacing: 0) {
                contactRow(title: "Whatsapp", icon: "whatsapp", iconColor: .green)
                Divider()
                contactRow(title: "Instagram", icon: "instagram", iconColor: .pink)
                Divider()
                contactRow(title: "Telegram", icon: "telegram", iconColor: .blue)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(UIColor.systemGray6))
        .navigationBarHidden(true)
    }
    
    // Contact Row
    func contactRow(title: String, icon: String, iconColor: Color) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                .padding(.trailing, 8)
            
            Text(title)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 16)
    }
}
