import Foundation

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    var isExpanded: Bool = false
}

class FAQViewModel: ObservableObject {
    @Published var items: [FAQItem] = [
        FAQItem(
            question: "How do I track my meals?",
            answer: "Go to the \"Food Diary\" and search for foods in our database. Tap on a food to add it to your daily log. You'll see calories, macronutrients, and serving size. Remember to log all your meals throughout the day for accurate tracking."
        ),
        FAQItem(
            question: "How do I update my profile?",
            answer: "Go to the Profile tab and tap the edit icon. From there, you can change your name, weight, goals, and other details."
        ),
        FAQItem(
            question: "What’s the best way to set my calorie goals?",
            answer: "Use the onboarding wizard or health goal screen to define your targets based on your current and target weight."
        ),
        FAQItem(
            question: "How can I sync my app with other health trackers?",
            answer: "Currently, syncing with Apple Health or Fitbit is in progress. Stay tuned for updates!"
        ),
        FAQItem(
            question: "What should I do if I forgot my password?",
            answer: "On the login screen, tap 'Forgot Password' and follow the instructions to reset via email."
        ),
        FAQItem(
            question: "How can I delete my account?",
            answer: "Go to Settings > Account > Delete Account. Note: this action is irreversible."
        )
    ]
    
    func toggleItem(_ item: FAQItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isExpanded.toggle()
        }
    }
}
