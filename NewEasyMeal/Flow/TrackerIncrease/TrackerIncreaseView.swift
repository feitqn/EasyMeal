
import SwiftUI

// MARK: - Tracker Data Model
struct TrackerData: Identifiable, Codable {
    let id: String
    let type: String
    var currentValue: Double
    var isCompleted: Bool?
    let dateCreated: Date?
    
    let title: String
    let goal: String
    
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
    
    var currentValueText: String {
        switch trackerType {
        case .noSugar, .noFastFood, .noLateNightEating:
            if currentValue == 0 {
                return "Not tracked"
            } else {
                return "Tracked"
            }
        default:
            return "\(Int(currentValue))"
        }
    }
}

// MARK: - Tracker ViewModel
class TrackerBottomSheetViewModel: ObservableObject {
    var onFinish: (() -> ())?
    
    @Published var currentTracker: TrackerData?
    @Published var tempValue: Double = 0.0
    @Published var isPresented: Bool = false
    
    func presentTracker(_ tracker: TrackerData) {
        currentTracker = tracker
        tempValue = tracker.currentValue
        isPresented = true
    }
    
    func increment() {
        let step = getStepValue()
        tempValue = max(0, tempValue + step)
    }
    
    func decrement() {
        let step = getStepValue()
        tempValue = max(0, tempValue - step)
    }
    
    func saveProgress() {
        guard var tracker = currentTracker else { return }
        tracker.currentValue = tempValue
        tracker.isCompleted = checkIfCompleted(for: tracker.trackerType, value: tempValue)
        
        Task {
            do {
                APIHelper.shared.updateTrackerCurrentValue(trackerId: tracker.id, newValue: tracker.currentValue)
                if tracker.trackerType == .steps {
                    APIHelper.shared.updateStepsInFoodDiart(steps: Int(tracker.currentValue))
                }
                NotificationCenter.default.post(name: .getProfile, object: self)
                NotificationCenter.default.post(name: .shouldFetchHomeData, object: self)
            } catch {
                print(error)
            }
        }
        // Здесь можно сохранить в базу данных или передать в родительский ViewModel
        dismiss()
    }
    
    
    func dismiss() {
        isPresented = false
        currentTracker = nil
        tempValue = 0.0
        
        onFinish?()
    }
    
//    private func getInitialValue(for type: TrackerData) -> Double {
//        switch type {
//        case .noSugar, .noFastFood, .noLateNightEating:
//            return 0.0 // Начинаем с "не выполнено"
//        default:
//            return 0.0
//        }
//    }
    
    private func getStepValue() -> Double {
        guard let tracker = currentTracker else { return 1.0 }
        
        switch tracker.trackerType {
        case .water:
            return 0.25 // 250ml шаги
        case .fruit, .vegetable:
            return 1.0 // по 1 порции
        case .protein:
            return 5.0 // по 5 грамм
        case .steps:
            return 500.0 // по 500 шагов
        case .noSugar, .noFastFood, .noLateNightEating:
            return 1.0 // 0 или 1 (не выполнено/выполнено)
        }
    }
    
    private func checkIfCompleted(for type: TrackerType, value: Double) -> Bool {
        switch type {
        case .water:
            return value >= 2.0
        case .fruit, .vegetable:
            return value >= 1.0
        case .protein:
            return value >= 50.0
        case .steps:
            return value >= 10000
        case .noSugar, .noFastFood, .noLateNightEating:
            return value == 1.0
        }
    }
}

// MARK: - Bottom Sheet View
struct TrackerBottomSheet: View {
    @ObservedObject var viewModel: TrackerBottomSheetViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            // Drag Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 12)
            
            if let tracker = viewModel.currentTracker {
                // Title
                VStack(spacing: 8) {
                    Text(getTitle(for: tracker.trackerType))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(tracker.trackerType.color)
                    
                    Text(tracker.goal)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { day in
                            getIconForTracker(trackerType: tracker.trackerType, isCompleted: true)
                        }
                    }
                }
                
                Spacer()
                
                // Value Display & Controls
                VStack(spacing: 30) {
                    // Current Value
                    VStack(spacing: 8) {
                        Text(formatValue(viewModel.tempValue, for: tracker.trackerType))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(tracker.trackerType.color)
                        
                        Text(getUnit(for: tracker.trackerType))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Plus/Minus Buttons
                    HStack(spacing: 60) {
                        // Minus Button
                        Button(action: {
                            viewModel.decrement()
                        }) {
                            Image(systemName: "minus")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.8))
                                )
                        }
                        
                        // Plus Button
                        Button(action: {
                            viewModel.increment()
                        }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(tracker.trackerType.color)
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: {
                    viewModel.saveProgress()
                }) {
                    Text("Save")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(tracker.trackerType.color)
                        )
                }
                .padding(.horizontal, 40)
                
                // Cancel Button
                Button(action: {
                    viewModel.dismiss()
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .ignoresSafeArea()
        )
    }
    
    @ViewBuilder
    func getIconForTracker(trackerType: TrackerType, isCompleted: Bool) -> some View {
        Image(trackerType.iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
            .foregroundColor(isCompleted ? Color.blue : Color.blue.opacity(0.2))
    }
    
    private func getTitle(for type: TrackerType) -> String {
        switch type {
        case .water:
            return "Water Intake"
        case .fruit:
            return "Fruit Intake"
        case .vegetable:
            return "Vegetable Intake"
        case .protein:
            return "Protein Intake"
        case .steps:
            return "Daily Steps"
        case .noSugar:
            return "No Sugar Challenge"
        case .noFastFood:
            return "No Fast Food Challenge"
        case .noLateNightEating:
            return "No Late Night Eating"
        }
    }
    
    private func getUnit(for type: TrackerType) -> String {
        switch type {
        case .water:
            return "Liters"
        case .fruit:
            return "Fruits"
        case .vegetable:
            return "Vegetables"
        case .protein:
            return "Grams"
        case .steps:
            return "Steps"
        case .noSugar, .noFastFood, .noLateNightEating:
            return viewModel.tempValue == 1.0 ? "Completed ✅" : "Not Completed ❌"
        }
    }
    
    private func formatValue(_ value: Double, for type: TrackerType) -> String {
        switch type {
        case .water:
            return String(format: "%.2f", value)
        case .noSugar, .noFastFood, .noLateNightEating:
            return value == 1.0 ? "Yes" : "No"
        default:
            return "\(Int(value))"
        }
    }
}

// MARK: - Usage Example
//struct TrackerMainView: View {
//    @StateObject private var bottomSheetViewModel = TrackerBottomSheetViewModel()
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                Text("Your Trackers")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                
//                // Example tracker buttons
//                ForEach([TrackerType.water, .fruit, .vegetable, .protein, .steps, .noSugar, .noFastFood, .noLateNightEating], id: \.self) { trackerType in
//                    Button(action: {
//                        bottomSheetViewModel.presentTracker(trackerType)
//                    }) {
//                        HStack {
//                            Text(getTitle(for: trackerType))
//                                .fontWeight(.semibold)
//                                .foregroundColor(.primary)
//                            
//                            Spacer()
//                            
//                            Image(systemName: "plus.circle.fill")
//                                .foregroundColor(trackerType.color)
//                        }
//                        .padding()
//                        .background(Color(.systemGray6))
//                        .cornerRadius(12)
//                    }
//                }
//                
//                Spacer()
//            }
//            .padding()
//            .sheet(isPresented: $bottomSheetViewModel.isPresented) {
//                TrackerBottomSheet(viewModel: bottomSheetViewModel)
//                    .presentationDetents([.medium])
//                    .presentationDragIndicator(.hidden)
//            }
//        }
//    }
//    
//    private func getTitle(for type: TrackerType) -> String {
//        switch type {
//        case .water:
//            return "Water Intake"
//        case .fruit:
//            return "Fruit Intake"
//        case .vegetable:
//            return "Vegetable Intake"
//        case .protein:
//            return "Protein Intake"
//        case .steps:
//            return "Daily Steps"
//        case .noSugar:
//            return "No Sugar Challenge"
//        case .noFastFood:
//            return "No Fast Food Challenge"
//        case .noLateNightEating:
//            return "No Late Night Eating"
//        }
//    }
//}
//
//// MARK: - Preview
//struct TrackerBottomSheet_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackerMainView()
//    }
//}
