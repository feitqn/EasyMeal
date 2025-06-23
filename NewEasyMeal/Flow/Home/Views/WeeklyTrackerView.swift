import SwiftUI

struct WeeklyTrackerView: View {
    let tracker: TrackerData
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(tracker.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(tracker.trackerType.color)
            
            Text(tracker.goal)
                .font(.system(size: 12))
                .foregroundColor(Color.secondary)
            
            Text("Current value: \(tracker.currentValueText)")
                .font(.system(size: 12))
                .foregroundColor(Color.black.opacity(0.6))
            
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { day in
                    getIconForTracker(tracker: tracker, isCompleted: true)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    func getIconForTracker(tracker: TrackerData, isCompleted: Bool) -> some View {
        Image(tracker.trackerType.iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
            .foregroundColor(isCompleted ? Color.blue : Color.blue.opacity(0.2))
    }
}
