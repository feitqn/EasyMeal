import SwiftUI

struct GoalSelectionView: View {
    @Binding var selectedGoal: Goal
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What is your current goal?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This helps provide accurate calorie and nutrition recommendations.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                ForEach(Goal.allCases, id: \.self) { goal in
                    GoalButton(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        action: { selectedGoal = goal }
                    )
                }
            }
            .padding()
        }
    }
}

struct GoalButton: View {
    let goal: Goal
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch goal {
        case .loss: return "arrow.down.circle.fill"
        case .maintenance: return "equal.circle.fill"
        case .gain: return "arrow.up.circle.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(goal.rawValue)
                    .font(.title3)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
} 