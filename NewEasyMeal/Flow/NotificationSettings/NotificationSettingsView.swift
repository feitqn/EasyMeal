import SwiftUI

enum TimeType: Identifiable {
    case breakfast, lunch, snack, dinner
    
    var id: Int { hashValue }
}

struct NotificationSettingsView: View {
    var onTapExit: Callback
    
    @State private var allReminders = true
    @State private var meal = true
    @State private var water = true
    @State private var activity = true
    @State private var progress = true
    @State private var recipes = true

    // Time states
    @State private var breakfastTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var lunchTime = Calendar.current.date(from: DateComponents(hour: 13, minute: 0)) ?? Date()
    @State private var snackTime = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()
    @State private var dinnerTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
    
    @State private var activeTimeType: TimeType?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    onTapExit()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 10)
            
            // Title
            HStack {
                Text("Notification")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Settings
            VStack(spacing: 0) {
                NotificationToggleRow(title: "All Reminders", isOn: $allReminders)
                Divider().padding(.horizontal, 20)

                NotificationToggleRow(title: "Meal", isOn: $meal)

                if meal {
                    VStack(spacing: 0) {
                        TimeRow(title: "Breakfast", time: formattedTime(breakfastTime)) {
                            activeTimeType = .breakfast
                        }
                        TimeRow(title: "Lunch", time: formattedTime(lunchTime)) {
                            activeTimeType = .lunch
                        }
                        TimeRow(title: "Snack", time: formattedTime(snackTime)) {
                            activeTimeType = .snack
                        }
                        TimeRow(title: "Dinner", time: formattedTime(dinnerTime)) {
                            activeTimeType = .dinner
                        }
                    }
                    .padding(.leading, 16)
                }

                Divider().padding(.horizontal, 20)
                NotificationToggleRow(title: "Water", isOn: $water)
                Divider().padding(.horizontal, 20)
                NotificationToggleRow(title: "Activity", isOn: $activity)
                Divider().padding(.horizontal, 20)
                NotificationToggleRow(title: "Progress", isOn: $progress)
                Divider().padding(.horizontal, 20)
                NotificationToggleRow(title: "Recipes", isOn: $recipes)
            }
            .padding(.top, 30)

            Spacer()
        }
        .background(Color(UIColor.white))
        .sheet(item: $activeTimeType) { type in
            VStack {
                Text("Select Time")
                    .font(.headline)
                    .padding()

                DatePicker("", selection: binding(for: type), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()

                Button("Done") {
                    activeTimeType = nil
                }
                .padding(.bottom)
            }
            .presentationDetents([.fraction(0.3)])
        }
    }

    private func binding(for type: TimeType) -> Binding<Date> {
        switch type {
        case .breakfast: return $breakfastTime
        case .lunch: return $lunchTime
        case .snack: return $snackTime
        case .dinner: return $dinnerTime
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TimeRow: View {
    let title: String
    let time: String
    var onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(time)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }
}

struct NotificationToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.black)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
    }
}
