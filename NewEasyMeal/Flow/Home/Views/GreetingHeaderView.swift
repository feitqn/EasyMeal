import SwiftUI

struct GreetingHeaderView: View {
    var userName: String
    var onBellTapped: (() -> Void)?

    var body: some View {
        HStack {
            HStack(spacing: 12) {

                if let avatar = UserManager.shared.getAvatarImage() {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .padding(8)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Circle())
                }

                Text("Hi, \(userName)!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }

            Spacer()

            Button(action: {
                onBellTapped?()
            }) {
                Image(systemName: "bell.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(UIColor.systemGray3))
                    .padding(10)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
}
