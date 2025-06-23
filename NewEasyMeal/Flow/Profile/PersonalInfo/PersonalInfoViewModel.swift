import SwiftUI

@MainActor
class PersonalInfoViewModel: ObservableObject {
    @Published var username = UserManager.shared.name
    @Published var email = UserManager.shared.getUserProfile()?.email ?? ""
    @Published var gender = UserManager.shared.getUserProfile()?.gender ?? "male"
    @Published var birthDate = UserManager.shared.getUserProfile()?.birthDate ?? Date()
    @Published var showBackButton = true

    enum Gender: String, CaseIterable, Identifiable {
        case female = "Female"
        case male = "Male"
        case other = "Other"

        var id: String { self.rawValue }
    }
    
    func saveChanges(completion: @escaping Callback) {
        guard !username.isEmpty, !gender.isEmpty else {
            return
        }

        Task {
            do {
                try await APIHelper.shared.updateUserProfileFields(
                    userId: UserManager.shared.userId,
                    fieldsToUpdate: [
                        "name": username,
                        "gender": gender,
                        "birthDate": Int(birthDate.timeIntervalSince1970)
                    ]
                )
                NotificationCenter.default.post(name: .getProfile, object: self)
                completion()
            } catch {
                print("Ошибка обновления профиля: \(error)")
            }
        }
    }
}

extension Binding<Date> {
    func mapToString(format: String = "yyyy-MM-dd") -> Binding<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        return Binding<String>(
            get: {
                formatter.string(from: self.wrappedValue)
            },
            set: { newValue in
                if let date = formatter.date(from: newValue) {
                    self.wrappedValue = date
                }
            }
        )
    }
}
