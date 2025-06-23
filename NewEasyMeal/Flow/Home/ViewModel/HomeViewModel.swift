import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var isLoading: Bool = true
    @Published var leftKcal = 0
    @Published var eaten = 0
    @Published var burned = 0
    @Published var currentWeight: Double = 0
    @Published var overallCalories: Int = 0
    @Published var goalWeight: Double = 0
    
    @Published var nutritionData: [Nutrition] = []
    
    @Published var mealData: [Meal] = []
    
    @Published var trackerData: [TrackerInfo] = []
    
    @Published var weeklyTrackers: [TrackerData] = []
    
    func upload() {
        Task {
            do {
                try await APIHelper.shared.uploadMockRecipesToFirebase()
            } catch {
                print(error)
            }
        }
    }
    
    func fetchFoodDiary() {
        Task {
            do {
                self.isLoading = true
                let user = try await APIHelper.shared.fetchProfile()
                userName = user.name
                let diary = try await APIHelper.shared.fetchFoodDiary()
                if let diary = diary {
                    self.overallCalories = diary.overallCalories ?? 0
                    self.eaten = diary.eatenCalories ?? 0
                    self.burned = diary.burnedCalories ?? 0
                    self.leftKcal = diary.remainingCalories ?? 0
                    self.nutritionData = diary.nutrition ?? []
                    self.mealData = diary.meals ?? []
                    self.isLoading = false
                    self.weeklyTrackers = diary.trackers ?? []
                    self.currentWeight = diary.currentWeight ?? 70
                    self.goalWeight = user.targetWeight
                    if let steps = diary.trackers?.first(where: { $0.trackerType == .steps }) {
                        self.burned = Int(caloriesBurned(steps: Int(steps.currentValue), weightKg: currentWeight))
                        self.trackerData = [TrackerInfo(title: "Steps", value: "\(steps.currentValue)", goal: "\(diary.steps?.target ?? 0)", progress: CGFloat((diary.steps?.current ?? 0) / (diary.steps?.target ?? 0))), TrackerInfo(title: "Exercise", value: "", goal: "", progress: 0)   ]
                    }
                } else {
                    guard let userProfile = UserManager.shared.getUserProfile(), let goal = userProfile.currentGoal else {
                        return
                    }
                    
                    let diary = FoodDiary.generatePlan(weight: userProfile.weight, targetWeight: userProfile.targetWeight, goal: goal.mapToWeightGoal())
                    
                    FirestoreManager.shared.createTodayFoodDiary(userId: userProfile.id, foodDiary: diary)
                    fetchFoodDiary()
                }
            } catch {
                print(error)
            }
        }
    }
    
    func getProfile() {
        Task {
            do {
                let user = try await APIHelper.shared.fetchProfile()
                userName
            } catch {
                print(error)
            }
        }
    }
    
    func updateWeight(weight: Double) {
        guard let userProfile = UserManager.shared.getUserProfile() else {
            return
        }
        Task {
            do {
                APIHelper.shared.updateCurrentWeight(weight)
                currentWeight = weight
            } catch {
                print(error)
            }
        }
    }
    
    func caloriesBurned(steps: Int, weightKg: Double) -> Double {
        // Среднее количество калорий, сжигаемых на 1 шаг (примерно 0.04-0.06 ккал для веса 70 кг)
        let caloriesPerStep = 0.0005 * weightKg
        return Double(steps) * caloriesPerStep
    }
}
