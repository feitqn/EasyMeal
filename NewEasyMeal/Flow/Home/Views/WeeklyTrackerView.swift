import SwiftUI

struct WeeklyTrackerView: View {
    let tracker: WeeklyTracker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tracker.title)
                .font(AppFonts.subheadline)
                .foregroundColor(tracker.color)
            
            Text("Goal: \(tracker.goal)")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(0..<tracker.totalDays, id: \.self) { day in
                    if tracker.title.contains("Water") {
                        Image(systemName: "drop.fill")
                            .foregroundColor(day < tracker.daysCompleted ? Color.blue : Color.blue.opacity(0.2))
                    } else if tracker.title.contains("Fruit") {
                        Image(systemName: "apple.logo")
                            .foregroundColor(day < tracker.daysCompleted ? tracker.color : tracker.color.opacity(0.2))
                    } else if tracker.title.contains("Vegetable") {
                        Image(systemName: "carrot.fill")  // Using similar icon as no specific carrot in SF Symbols
                            .foregroundColor(day < tracker.daysCompleted ? tracker.color : tracker.color.opacity(0.2))
                    } else if tracker.title.contains("Protein") {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")  // Similar icon for protein
                            .foregroundColor(day < tracker.daysCompleted ? tracker.color : tracker.color.opacity(0.2))
                    } else if tracker.title.contains("Steps") {
                        Image(systemName: "figure.walk")
                            .foregroundColor(day < tracker.daysCompleted ? tracker.color : tracker.color.opacity(0.2))
                    } else if tracker.title.contains("Sugar") {
                        Circle()
                            .stroke(tracker.color, lineWidth: 1)
                            .frame(width: 20, height: 20)
                            .overlay(
                                day < tracker.daysCompleted ?
                                Circle().foregroundColor(tracker.color).frame(width: 12, height: 12) : nil
                            )
                    } else if tracker.title.contains("Fast Food") {
                        Image(systemName: "bag.fill")
                            .foregroundColor(day < tracker.daysCompleted ? tracker.color : tracker.color.opacity(0.2))
                    } else if tracker.title.contains("Late-Night") {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(day < tracker.daysCompleted ? tracker.color : tracker.color.opacity(0.2))
                    } else {
                        Image(systemName: tracker.iconName)
                            .foregroundColor(day < tracker.daysCompleted ? tracker.color : tracker.color.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

