import Foundation

final class UserManager {
    static let shared = UserManager()

    func save(userProfile: UserProfile) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }

        userId = userProfile.id
        name = userProfile.name
    }
    
    func logout() {
        userId = ""
    }

    func getUserProfile() -> UserProfile? {
        if let savedData = UserDefaults.standard.data(forKey: "userProfile") {
            let decoder = JSONDecoder()
            if let loadedProfile = try? decoder.decode(UserProfile.self, from: savedData) {
                return loadedProfile
            }
        }
        return nil
    }
}

extension UserManager {
    var userId: String {
        get {
            UserDefaults.standard.string(forKey: "userID") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userID")
        }
    }
    
    var name: String {
        get {
            UserDefaults.standard.string(forKey: "name") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "name")
        }
    }
}
