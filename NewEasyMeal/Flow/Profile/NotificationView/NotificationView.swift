import SwiftUI

// MARK: - Notifications View
struct NotificationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    // Back button action
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.gray.opacity(0.2), radius: 2)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Title
            Text("Notifications")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Notifications List
            ScrollView {
                VStack(spacing: 10) {
                    notificationItem(title: "Water", message: "Don't forget to sip! 💧", time: "1 min ago")
                    notificationItem(title: "Calories", message: "Let's log that meal🍽️", time: "10 min ago")
                    notificationItem(title: "Breakfast", message: "Start your day deliciously ☀️", time: "10 min ago")
                    notificationItem(title: "Lunch", message: "What's on your plate today? 🥗", time: "10 min ago")
                    notificationItem(title: "Dinner", message: "Time to wind down with a healthy meal 🍲", time: "10 min ago")
                    notificationItem(title: "Snacks", message: "A little something between meals? 🍎", time: "10 min ago")
                    notificationItem(title: "Hydration", message: "You're doing great, keep sipping! 🧃", time: "10 min ago")
                    notificationItem(title: "Steps", message: "A little movement goes a long way 👣", time: "10 min ago")
                    notificationItem(title: "Activity", message: "Nice work! Let's log your workout 💪", time: "10 min ago")
                    notificationItem(title: "Weight", message: "How's your progress today? ⚖️", time: "10 min ago")
                    notificationItem(title: "Recipe", message: "Need inspiration? We've got ideas! 🔍", time: "10 min ago")
                    notificationItem(title: "Reminder", message: "Just a gentle nudge to stay on track 📝", time: "10 min ago")
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 16)
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    func notificationItem(title: String, message: String, time: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "bell.fill")
                    .foregroundColor(.black)
                    .font(.system(size: 16))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Time
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}
