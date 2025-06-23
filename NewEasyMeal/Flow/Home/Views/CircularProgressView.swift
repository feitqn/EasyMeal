import SwiftUI

struct CircularProgressView: View {
    let progress: CGFloat
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let text: String
    
    init(progress: CGFloat, color: Color = AppColors.primary, size: CGFloat = 150, lineWidth: CGFloat = 10, text: String = "") {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.text = text
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.1)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            
            if !text.isEmpty {
                VStack {
                    Text(text)
                        .font(.system(size: 24, weight: .bold))
                    Text("kcal left")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

enum AppColors {
    static let primary = Colors.greenColor
    static let secondary = Color.gray.opacity(0.1)
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    
    static let carbsColor = Color.blue
    static let proteinColor = Color.orange
    static let fatColor = Color.purple
    
    static let breakfastColor = Color.blue
    static let lunchColor = Color.orange
    static let snackColor = Color.red
    static let dinnerColor = Color.purple
    
    static let stepsColor = Color.orange
    static let exerciseColor = Color.orange
    
    static let fruitColor = Color.red
    static let vegetableColor = Color.orange
    static let proteinTrackerColor = Color.pink
    static let noSugarColor = Color.red
    static let noFastFoodColor = Color.orange
    static let noLateNightColor = Color.red
}

enum AppFonts {
    static let title = Font.title.bold()
    static let headline = Font.headline
    static let subheadline = Font.urbanSemiBold(size: 20)
    static let caption = Font.urban(size: 12)
    static let body = Font.body
}

struct MealInfo: Identifiable {
    let id = UUID()
    let title: String
    let image: String // Could be an actual image name or system name
    let caloriesConsumed: Int
    let caloriesGoal: Int
    
    var caloriesText: String {
        return "\(caloriesConsumed)/\(caloriesGoal) kcal"
    }
    
    var progress: CGFloat {
        return caloriesConsumed > 0 ? CGFloat(caloriesConsumed) / CGFloat(caloriesGoal) : 0
    }
}

struct TrackerInfo: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let goal: String
    let progress: CGFloat
}

struct Tracker: Identifiable, Codable {
    let id: String
    let title: String
    let goal: String
    let type: String
    
    var trackerType: TrackerType {
        switch type {
        case "water": return .water
        case "fruit": return .fruit
        case "vegetable": return .vegetable
        case "protein": return .protein
        case "steps": return .steps
        case "noSugar": return .noSugar
        case "noFastFood": return .noFastFood
        case "noLateNightEating": return .noLateNightEating
        default: return .water
        }
    }
}

enum CustomIconType {
    case water, fruit, vegetable, protein, steps, sugarChallenge, fastFood, lateNight
}
