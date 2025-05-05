
import SwiftUI

struct SelectGoalView: View {
    @ObservedObject var viewModel: SelectGoalViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Spacer()
                Button(action: {
                    viewModel.continueTapped()
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .padding(.horizontal)

            // Title
            Text("What is your goal?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)

            // Goal buttons
            ForEach(SelectGoalViewModel.Goal.allCases) { goal in
                Button(action: {
                    viewModel.select(goal: goal)
                }) {
                    HStack {
                        Image(systemName: icon(for: goal))
                        Text(goal.rawValue)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.selectedGoal == goal ? Color.green : Color.gray.opacity(0.2))
                    .foregroundColor(viewModel.selectedGoal == goal ? .white : .black)
                    .cornerRadius(12)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }

    func icon(for goal: SelectGoalViewModel.Goal) -> String {
        switch goal {
        case .loseWeight: return "flame.fill"
        case .maintainWeight: return "equal"
        case .gainWeight: return "bolt.fill"
        }
    }
}
