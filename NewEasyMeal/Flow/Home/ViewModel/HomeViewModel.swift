import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var leftKcal = 0
    @Published var eaten = 0
    @Published var burned = 0
    
    @Published var nutritionData: [Nutrition] = []
    
    @Published var mealData: [Meal] = []
    
    @Published var trackerData: [TrackerInfo] = []
    
    @Published var weeklyTrackers = [
        WeeklyTracker(title: "Track Your Water Intake", goal: "2.00 L", color: Color.blue, iconName: "drop.fill", daysCompleted: 0)
//        ,
//        WeeklyTracker(title: "Track Your Weekly Fruit Intake", goal: "1 or 2 fruits per day", color: AppColors.fruitColor, iconName: "apple.logo", daysCompleted: 0),
//        WeeklyTracker(title: "Track Your Weekly Vegetable Intake", goal: "1 or 2 vegetables per day", color: AppColors.vegetableColor, iconName: "leaf.fill", daysCompleted: 0),
//        WeeklyTracker(title: "Track Your Weekly Protein Intake", goal: "0.8g per kg of body weight", color: AppColors.proteinTrackerColor, iconName: "takeoutbag.and.cup.and.straw.fill", daysCompleted: 0),
//        WeeklyTracker(title: "Track Your Steps Weekly", goal: "10000", color: AppColors.stepsColor, iconName: "figure.walk", daysCompleted: 0),
//        WeeklyTracker(title: "Weekly No Sugar Challenge", goal: "0g of added sugar per day", color: AppColors.noSugarColor, iconName: "circle", daysCompleted: 0),
//        WeeklyTracker(title: "Weekly No Fast Food Challenge", goal: "0 fast food meals per day", color: AppColors.noFastFoodColor, iconName: "bag.fill", daysCompleted: 0),
//        WeeklyTracker(title: "Weekly No Late-Night Eating Challenge", goal: "No food after 8:00 PM", color: AppColors.noLateNightColor, iconName: "moon.stars.fill", daysCompleted: 0)
    ]
    
    func fetchFoodDiary() {
        Task {
            do {
                self.isLoading = true
                let diary = try await APIHelper.shared.fetchFoodDiary()
                if let diary = diary {
                    self.eaten = diary.eatenCalories
                    self.burned = diary.burnedCalories
                    self.leftKcal = diary.remainingCalories
                    self.nutritionData = diary.nutrition
                    self.mealData = diary.meals
                    self.trackerData = [TrackerInfo(title: "Steps", value: "\(diary.steps.current)", goal: "\(diary.steps.target)", progress: CGFloat(diary.steps.current / diary.steps.target)),TrackerInfo(title: "Exercise", value: "", goal: "", progress: 0)]
                    self.isLoading = false
                } else {
                    guard let userProfile = UserManager.shared.getUserProfile(), let goal = userProfile.currentGoal   else {
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
}
