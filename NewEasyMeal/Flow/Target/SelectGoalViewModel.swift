import SwiftUI

class SelectGoalViewModel: ObservableObject {
    enum Goal: String, CaseIterable, Identifiable {
        case loseWeight = "Lose Weight"
        case maintainWeight = "Maintain Weight"
        case gainWeight = "Gain Weight"
        
        var id: String { self.rawValue }
    }
    
    @Published var selectedGoal: Goal? = nil
    func select(goal: Goal) {
        selectedGoal = goal
    }
    
    func continueTapped() {
        guard let goal = selectedGoal else { return }
        print("User selected goal: \(goal.rawValue)")
    }
}
