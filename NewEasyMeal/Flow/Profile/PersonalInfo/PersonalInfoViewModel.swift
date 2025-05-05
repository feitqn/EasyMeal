import SwiftUI

class PersonalInfoViewModel: ObservableObject {
    @Published var username: String = "Aiganym"
    @Published var email: String = "aiganym@gmail.com"
    @Published var gender: Gender = .female
    @Published var birthday: Date = DateComponents(calendar: Calendar.current, year: 1982, month: 4, day: 15).date ?? Date()

    enum Gender: String, CaseIterable, Identifiable {
        case female = "Female"
        case male = "Male"
        case other = "Other"

        var id: String { self.rawValue }
    }
    
    func saveChanges() {
        // Здесь логика сохранения данных (например, отправка на сервер)
        print("Saved: \(username), \(email), \(gender.rawValue), \(birthday)")
    }
}
