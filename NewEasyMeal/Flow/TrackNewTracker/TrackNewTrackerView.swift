import SwiftUI

struct TrackerOption: Identifiable {
    let id = UUID()
    let title: String
    let type: TrackerType
}

enum TrackerType: String, Codable {
    case water
    case fruit
    case vegetable
    case protein
    case steps
    case noSugar
    case noFastFood
    case noLateNightEating
    
    var goal: String {
        switch self {
        case .water:
            "Goal: 2,00 L"
        case .fruit:
            "Goal: 1 or 2 fruits per day"
        case .vegetable:
            "Goal: 1 or 2 vegetables per day"
        case .protein:
            "Goal: 0.8g per kg of body weight"
        case .steps:
            "Goal: 10000 steps"
        case .noSugar:
            "Goal: 0g of added sugar per day"
        case .noFastFood:
            "Goal: 0 fast food meals per day"
        case .noLateNightEating:
            "Goal: No food after 8:00 PM"
        }
    }
    
    var iconName: String {
        switch self {
        case .water:
            "water"
        case .fruit:
            "fruit"
        case .vegetable:
            "carrot"
        case .protein:
            "meat"
        case .steps:
            "walk"
        case .noSugar:
            "sugarfree"
        case .noFastFood:
            "fastFood"
        case .noLateNightEating:
            "noLate"
        }
    }
//        WeeklyTracker(title: "Track Your Weekly Fruit Intake", goal: "1 or 2 fruits per day", color: AppColors.fruitColor, iconName: "fruit", totalDays: 5, daysCompleted: 0),
//        WeeklyTracker(title: "Track Your Weekly Vegetable Intake", goal: "1 or 2 vegetables per day", color: AppColors.vegetableColor, iconName: "carrot", totalDays: 6, daysCompleted: 0),
//        WeeklyTracker(title: "Track Your Weekly Protein Intake", goal: "0.8g per kg of body weight", color: AppColors.proteinTrackerColor, iconName: "meat", totalDays: 5, daysCompleted: 0),
//        WeeklyTracker(title: "Track Your Steps Weekly", goal: "10000", color: AppColors.stepsColor, iconName: "walk", totalDays: 6, daysCompleted: 0),
//        WeeklyTracker(title: "Weekly No Sugar Challenge", goal: "0g of added sugar per day", color: AppColors.noSugarColor, iconName: "sugarfree", totalDays: 5, daysCompleted: 0),
//        WeeklyTracker(title: "Weekly No Fast Food Challenge", goal: "0 fast food meals per day", color: AppColors.noFastFoodColor, iconName: "fastFood", totalDays: 6, daysCompleted: 0),
//        WeeklyTracker(title: "Weekly No Late-Night Eating Challenge", goal: "No food after 8:00 PM", color: AppColors.noLateNightColor, iconName: "noLate", totalDays: 5, daysCompleted: 0)
    
    var color: Color {
        switch self {
        case .water:
            Color.blue
        case .fruit:
            AppColors.fruitColor
        case .vegetable:
            AppColors.vegetableColor
        case .protein:
            AppColors.proteinTrackerColor
        case .steps:
            AppColors.stepsColor
        case .noSugar:
            AppColors.noSugarColor
        case .noFastFood:
            AppColors.noFastFoodColor
        case .noLateNightEating:
            AppColors.noLateNightColor
        }
    }
}

struct TrackerSelectionView: View {
    
    var buttonTapped: (() -> Void)
    @ObservedObject var viewModel: TrackerViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Иконка и заголовок
            VStack {
                HStack {
                    Image("tracker")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.purple)
                    Spacer()
                }
                HStack {
                    Text("Track Your Nutrition & Hydration")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }

            // Список трекеров
            ForEach(viewModel.options) { option in
                Button(action: {
                    viewModel.selectedOptionID = option.id
                }) {
                    HStack {
                        Image(systemName: viewModel.selectedOptionID == option.id ? "checkmark.square.fill" : "square")
                            .foregroundColor(.orange)
                        Text(option.title)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }

            Spacer()

            // Кнопка
            Button(action: {
                buttonTapped()
            }) {
                Text("Add tracker")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
            }
        }
        .padding()
    }
}
