import SwiftUI

@MainActor
class HealthGoalsViewModel: ObservableObject {
    @Published var goal: String
    @Published var height: Double
    @Published var currentWeight: Double
    @Published var targetWeight: Double
    @Published var weeklyGoal: String
    @Published var dailyCalories: Int
    @Published var steps: Int
    @Published var water: Int
    
    init(profile: UserProfile? = UserManager.shared.getUserProfile()) {
        self.goal = profile?.currentGoal ?? "Maintain"
        self.height = Double(profile?.height ?? 170)
        self.currentWeight = profile?.weight ?? 65
        self.targetWeight = profile?.targetWeight ?? 60
        self.weeklyGoal = "-0.5 kg"
        self.dailyCalories = 2100
        self.steps = 10000
        self.water = 2000
    }
    
    func saveChanges(completion: @escaping Callback) {
        guard !goal.isEmpty else {
            return
        }

        Task {
            do {
                try await APIHelper.shared.updateUserProfileFields(
                    userId: UserManager.shared.userId,
                    fieldsToUpdate: [
                        "weight": currentWeight,
                        "targetWeight": targetWeight,
                        "height": height,
                        "currentGoal": goal,
                    ]
                )
                NotificationCenter.default.post(name: .getProfile, object: self)
                
                completion()
            } catch {
                print("Ошибка обновления профиля: \(error)")
            }
        }
    }
}
