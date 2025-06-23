import SwiftUI
import SkeletonUI

// MARK: - ContentView
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var onSelectMeal: ((Meal) -> Void)?
    var onTapAddNewTracker: (() -> ())?
    var onTapNotification: (() -> ())?
    var onTapTracker: ((TrackerData) -> ())

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Greeting header
                GreetingHeaderView(userName: UserManager.shared.getUserProfile()?.name ?? "", onBellTapped: onTapNotification)
                    .skeleton(
                        with: viewModel.isLoading,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: 30),
                        shape: .rounded(.radius(40, style: .circular))
                    )

                // Header
                HStack {
                    Text("Food Diary")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                // Calorie summary card
                CalorieSummaryCardView(
                    nutritionData: viewModel.nutritionData,
                    eatenCalories: viewModel.eaten,
                    burnedCalories: viewModel.burned,
                    remainingCalories: viewModel.leftKcal,
                    progressPercentage: Double(viewModel.leftKcal) / Double(viewModel.overallCalories)
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
                TrackersView(trackers: viewModel.trackerData, burned: viewModel.burned, onTapTracker: { type in
//                    onTapTracker(type)
                })
                    .skeleton(
                        with: viewModel.isLoading,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: 75),
                        shape: .rounded(.radius(40, style: .circular))
                    )
                // Weight measurement
                WeightMeasurementView(
                    currentWeight: $viewModel.currentWeight,
                    goalWeight: viewModel.goalWeight,
                    onUpdateTapped: { tempWeight in
                        viewModel.updateWeight(weight: tempWeight)
                    }
                )
                .skeleton(
                    with: viewModel.isLoading,
                    size: CGSize(width: UIScreen.main.bounds.width - 32, height: 60),
                    shape: .rounded(.radius(40, style: .circular))
                )
                // Weeklмy trackers
                WeeklyTrackersView(trackers: viewModel.weeklyTrackers,
                                   onTapTracker: { tracker in
                        onTapTracker(tracker)
                })
                    .skeleton(
                        with: viewModel.isLoading,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: 90),
                        shape: .rounded(.radius(40, style: .circular))
                    )
                // Add new tracker button
                CustomButtonView(title: "Add new tracker") {
                    onTapAddNewTracker?()
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
    let burned: Int
    let onTapTracker: ((TrackerType) ->())
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(trackers) { tracker in
                TrackerCard(tracker: tracker, burned: burned)
                    .onTapGesture {
                        onTapTracker(.steps)
                    }
            }
        }
        .padding(.horizontal)
    }
}

struct WeightMeasurementView: View {
    @Binding var currentWeight: Double
    let goalWeight: Double
    
    var onUpdateTapped: ((Double) -> ())

    @State private var tempWeight: Double
    @State private var isDragging = false
    @State private var showConfirmation = false

    init(currentWeight: Binding<Double>, goalWeight: Double, onUpdateTapped: @escaping ((Double) -> ()) ) {
        self._currentWeight = currentWeight
        self.goalWeight = goalWeight
        self._tempWeight = State(initialValue: currentWeight.wrappedValue)
        self.onUpdateTapped = onUpdateTapped
    }

    var progress: CGFloat {
        guard goalWeight > 0 else { return 0 }
        return min(max(CGFloat(tempWeight / goalWeight), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight measurement")
                .font(AppFonts.subheadline)
                .fontWeight(.medium)

            Text("Goal: \(String(format: "%.1f", goalWeight)) kg")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)

            Text("\(String(format: "%.1f", tempWeight)) kg")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 5)

            Slider(
                value: $tempWeight,
                in: 30...goalWeight,
                step: 0.1,
                onEditingChanged: { editing in
                    if !editing {
                        showConfirmation = true
                    }
                }
            )
            .accentColor(Color.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .alert("Вы уверены, что хотите изменить вес?", isPresented: $showConfirmation) {
            Button("Сохранить", role: .none) {
                onUpdateTapped(tempWeight)
                // Можешь вызвать тут updateCurrentWeight(currentWeight)
            }
            Button("Отменить", role: .cancel) {
                tempWeight = currentWeight
            }
        }
    }
}



// MARK: - Weekly Trackers View
struct WeeklyTrackersView: View {
    let trackers: [TrackerData]
    let onTapTracker: ((TrackerData) -> ())
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(trackers) { tracker in
                WeeklyTrackerView(tracker: tracker)
                    .padding(.horizontal)
                    .onTapGesture {
                        onTapTracker(tracker)
                    }
            }
        }
    }
}
