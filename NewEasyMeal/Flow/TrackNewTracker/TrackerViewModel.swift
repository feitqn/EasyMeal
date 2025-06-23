import Foundation

class TrackerViewModel: ObservableObject {
    // Список опций
    let options: [TrackerOption] = [
        TrackerOption(title: "Track Your Water Intake", type: .water),
        TrackerOption(title: "Track Your Fruit Intake", type: .fruit),
        TrackerOption(title: "Track Your Vegetable Intake", type: .vegetable),
        TrackerOption(title: "Track Your Protein Intake", type: .protein),
        TrackerOption(title: "Track Your Steps Weekly", type: .steps),
        TrackerOption(title: "No Sugar Challenge", type: .noSugar),
        TrackerOption(title: "No Fast Food Challenge", type: .noFastFood),
        TrackerOption(title: "No Late-Night Eating Challenge", type: .noLateNightEating)
    ]
    
    @Published var selectedOptionID: UUID?

    func addTracker(completion: @escaping () -> Void) {
        guard let selected = options.first(where: { $0.id == selectedOptionID })?.maptToTracker() else {
            return
        }

        APIHelper.shared.addTrackersToTodayDiary(trackers: [selected])
        
        NotificationCenter.default.post(name: .shouldFetchHomeData, object: nil)
        
        DispatchQueue.main.async {
            completion()
        }
    }
}

extension TrackerOption {
    func maptToTracker() -> TrackerData {
        return TrackerData(id: id.uuidString, type: type.rawValue, currentValue: 0, dateCreated: nil, title: title, goal: type.goal)
    }
}
