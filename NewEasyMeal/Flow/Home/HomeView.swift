import SwiftUI
import SkeletonUI

// MARK: - ContentView
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var onSelectMeal: ((Meal) -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GreetingHeaderView(userName: UserManager.shared.getUserProfile()?.name ?? "")
                    .skeleton(
                        with: viewModel.isLoading,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: 30),
                        shape: .rounded(.radius(40, style: .circular))
                    )

        
                HStack {
                    Text("Food Diary")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
         
                CalorieSummaryCardView(
                    nutritionData: viewModel.nutritionData,
                    eatenCalories: viewModel.eaten,
                    burnedCalories: viewModel.burned,
                    remainingCalories: viewModel.leftKcal,
                    progressPercentage: 0.7
                )
                .skeleton(
                    with: viewModel.isLoading,
                    size: CGSize(width: UIScreen.main.bounds.width - 32, height: 230),
                    shape: .rounded(.radius(40, style: .circular))
                )
                // Meals list
                MealsListView(meals: viewModel.mealData, onSelectMeal: { meal in
                    onSelectMeal?(meal)
                })
                
                // Trackers
                TrackersView(trackers: viewModel.trackerData)
                    .skeleton(
                        with: viewModel.isLoading,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: 75),
                        shape: .rounded(.radius(40, style: .circular))
                    )
                // Weight measurement
                WeightMeasurementView(
                    currentWeight: 70.0,
                    goalWeight: 60.0,
                    progress: 0.7
                )
                .skeleton(
                    with: viewModel.isLoading,
                    size: CGSize(width: UIScreen.main.bounds.width - 32, height: 60),
                    shape: .rounded(.radius(40, style: .circular))
                )
                // Weeklмy trackers
                WeeklyTrackersView(trackers: viewModel.weeklyTrackers)
                    .skeleton(
                        with: viewModel.isLoading,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: 90),
                        shape: .rounded(.radius(40, style: .circular))
                    )
                // Add new tracker button
                CustomButtonView(title: "Add new tracker") {
                    // Action for add button
                }
                .frame(width: 300, height: 60)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
        .padding(.top, 1)
        .background(Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all))
    }
}

// For Image preview representation (since we don't have actual images)
extension Image {
    init(_ name: String) {
        // This is a fallback for preview - in real app will use actual images
        if UIImage(named: name) != nil {
            self.init(name, bundle: nil)
        } else {
            // Use SF Symbols as placeholders
            switch name {
            case "breakfast":
                self.init(systemName: "cup.and.saucer.fill")
            case "lunch":
                self.init(systemName: "fork.knife")
            case "snack":
                self.init(systemName: "carrot.fill")
            case "dinner":
                self.init(systemName: "takeoutbag.and.cup.and.straw.fill")
            default:
                self.init(systemName: "circle.fill")
            }
        }
    }
}

// MARK: - Calorie Summary Card
struct CalorieSummaryCardView: View {
    let nutritionData: [Nutrition]
    
    let eatenCalories: Int
    let burnedCalories: Int
    let remainingCalories: Int
    let progressPercentage: CGFloat
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Eaten")
                            .font(AppFonts.subheadline)
                    }
                    
                    Text("\(eatenCalories)")
                        .font(.title3)
                        .fontWeight(.bold) +
                    Text(" kcal")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Burned")
                            .font(AppFonts.subheadline)
                    }
                    
                    Text("\(burnedCalories)")
                        .font(.title3)
                        .fontWeight(.bold) +
                    Text(" kcal")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: progressPercentage,
                    text: "\(remainingCalories)"
                )
            }
            .padding()
            
            // Nutrition progress bars
            HStack(spacing: 15) {
                ForEach(nutritionData) { nutrition in
                    NutritionProgressBar(info: nutrition)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct MealsListView: View {
    let meals: [Meal]
    let onSelectMeal: ((Meal) -> ())?
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(meals) { meal in
                MealCard(meal: meal) {
                    onSelectMeal?(meal)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TrackersView: View {
    let trackers: [TrackerInfo]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(trackers) { tracker in
                TrackerCard(tracker: tracker)
            }
        }
        .padding(.horizontal)
    }
}

struct WeightMeasurementView: View {
    let currentWeight: Double
    let goalWeight: Double
    let progress: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight measurement")
                .font(AppFonts.subheadline)
                .fontWeight(.medium)
            
            Text("Goal: \(String(format: "%.1f", goalWeight)) kg")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text("\(String(format: "%.1f", currentWeight)) kg")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 5)
            
            Slider(value: .constant(progress), in: 0...1)
                .accentColor(Color.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Weekly Trackers View
struct WeeklyTrackersView: View {
    let trackers: [WeeklyTracker]
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(trackers) { tracker in
                WeeklyTrackerView(tracker: tracker)
                    .padding(.horizontal)
            }
        }
    }
}
