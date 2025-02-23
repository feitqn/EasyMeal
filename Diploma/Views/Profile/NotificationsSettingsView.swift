import SwiftUI

struct NotificationsSettingsView: View {
    @StateObject private var settingsService = SettingsService.shared
    @AppStorage("enableDailyReminder") private var enableDailyReminder = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime = Date()
    @AppStorage("enableWeeklyReport") private var enableWeeklyReport = false
    @AppStorage("weeklyReportDay") private var weeklyReportDay = 1 // Понедельник
    
    private let weekDays = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
    
    var body: some View {
        Form {
            Section(header: Text("Ежедневные напоминания")) {
                Toggle("Напоминания о воде", isOn: Binding(
                    get: { settingsService.waterNotificationsEnabled },
                    set: { settingsService.toggleWaterNotifications($0) }
                ))
                
                Toggle("Напоминания о приемах пищи", isOn: Binding(
                    get: { settingsService.mealNotificationsEnabled },
                    set: { settingsService.toggleMealNotifications($0) }
                ))
                
                if settingsService.waterNotificationsEnabled || settingsService.mealNotificationsEnabled {
                    DatePicker("Время напоминания", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("Еженедельный отчет")) {
                Toggle("Включить еженедельный отчет", isOn: $enableWeeklyReport)
                
                if enableWeeklyReport {
                    Picker("День отчета", selection: $weeklyReportDay) {
                        ForEach(0..<weekDays.count, id: \.self) { index in
                            Text(weekDays[index]).tag(index + 1)
                        }
                    }
                }
            }
        }
        .navigationTitle("Уведомления")
    }
} 