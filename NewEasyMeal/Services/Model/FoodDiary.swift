import Foundation
import SwiftUI

struct Steps: Codable {
    let current: Int
    let target: Int
}

struct Nutrition: Codable, Identifiable {
    let id = UUID()
    let name: String
    let target: Int
    let current: Int
    
    var remainingText: String {
        return "\(target - current) kcal"
    }

    var progress: CGFloat {
        return current > 0 ? CGFloat(current) / CGFloat(target) : 0
    }
}

struct Exercise: Codable {
    let kcal: Int
    let duration: Int
}

struct WaterIntake: Codable {
    let target: Double
    let current: Double
}

struct FoodDiary: Codable {
    var eatenCalories: Int
    var burnedCalories: Int
    var remainingCalories: Int
    var meals: [Meal]
    var nutrition: [Nutrition]
    var steps: Steps
    var exercise: Exercise
    var waterIntake: WaterIntake
    
    static func generatePlan(weight: Double, targetWeight: Double, goal: WeightGoal) -> Self {
        var baseCalories = weight * 22.0 * 1.3
        
        switch goal {
        case .loseWeight:
            baseCalories -= 500
        case .gainWeight:
            baseCalories += 300
        case .maintainWeight:
            break
        }
        
        let dailyCalories = Int(baseCalories)
        
        let meals: [Meal] = [
            Meal(name: "breakfast", calories: 0, target: Int(baseCalories * 0.25)),
            Meal(name: "lunch",     calories: 0, target: Int(baseCalories * 0.3)),
            Meal(name: "dinner",    calories: 0, target: Int(baseCalories * 0.3)),
            Meal(name: "snack",     calories: 0, target: Int(baseCalories * 0.15))
        ]
        
        let carbs = Int((baseCalories * 0.4) / 4)
        let protein = Int((baseCalories * 0.3) / 4)
        let fat = Int((baseCalories * 0.3) / 9)
        
        var nutriotion: [Nutrition] = [
            Nutrition(name: "Carbs", target: carbs, current: 0),
            Nutrition(name: "Protein", target: protein, current: 0),
            Nutrition(name: "Fat", target: fat, current: 0)
        ]
        
        let stepsGoal: Int = {
            switch goal {
            case .loseWeight: return 10000
            case .maintainWeight: return 7000
            case .gainWeight: return 5000
            }
        }()
        
        let waterGoal = round((weight * 35 / 1000) * 10) / 10
        
        return FoodDiary(
            eatenCalories: 0,
            burnedCalories: 0,
            remainingCalories: dailyCalories,
            meals: meals,
            nutrition: nutriotion,
            steps: Steps(current: 0, target: stepsGoal),
            exercise: Exercise(kcal: 0, duration: 0),
            waterIntake: WaterIntake(target: waterGoal, current: 0))
    }
}

struct UserPlan {
    let dailyCalories: Int
    let meals: [Meal]
    let carbs: Int
    let protein: Int
    let fat: Int
    let stepsGoal: Int
    let waterIntakeGoal: Double
}

struct Meal: Codable, Identifiable {
    let id = UUID()
    var name: String
    var calories: Int
    var target: Int
    
    var progress: CGFloat {
        return calories > 0 ? CGFloat(calories) / CGFloat(target) : 0
    }
    
    var progressStr: String {
        return "\(calories)/\(target)"
    }
}

extension Meal {
    func mapToMealType() -> MealType {
        switch name.lowercased() {
        case MealType.breakFast.rawValue.lowercased():
            return .breakFast
        case MealType.lunch.rawValue.lowercased():
            return .lunch
        case MealType.snack.rawValue.lowercased():
            return .snack
        case MealType.dinner.rawValue.lowercased():
            return .dinner
        default:
            return .breakFast
        }
    }
}

enum MealType: String {
    case breakFast = "Breakfast"
    case lunch = "Lunch"
    case snack = "Snack"
    case dinner = "Dinner"
}

enum CurrentGoal {
    case lose
    case maintain
    case gain
}

enum WeightGoal: String, Codable, Identifiable, CaseIterable {
    case loseWeight = "lose"
    case maintainWeight = "maintain"
    case gainWeight = "gain"
    
    var id: String { rawValue }
    
    var image: Image {
        switch self {
        case .loseWeight:
            Image("loseWeight")
        case .maintainWeight:
            Image("maintainWeight")
        case .gainWeight:
            Image("gainWeight")
        }
    }
    
    var title: String {
        switch self {
        case .loseWeight:
            "Lose"
        case .maintainWeight:
            "Maintain"
        case .gainWeight:
            "Gain"
        }
    }
}

extension String {
    func mapToWeightGoal() -> WeightGoal {
        switch self.lowercased() {
        case WeightGoal.loseWeight.rawValue.lowercased():
            return .loseWeight
        case WeightGoal.maintainWeight.rawValue.lowercased():
            return .maintainWeight
        case WeightGoal.gainWeight.rawValue.lowercased():
            return .gainWeight
        default:
            return .loseWeight
        }
    }
}
