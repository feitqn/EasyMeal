import Foundation
import UIKit

final class UserManager {
    static let shared = UserManager()

    private let profileKey = "userProfile"
    private let avatarPathKey = "avatarPath"
    private let userIdKey = "userID"
    private let nameKey = "name"
    private let isFirstLaunchKey = "isFirstLaunch"

    // MARK: - Save
    
    func setIsFirstLaunch() {
        UserDefaults.standard.set(false, forKey: isFirstLaunchKey)
    }

    func save(userProfile: UserProfile, avatarImage: UIImage? = nil) {
        // Сохраняем профиль
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }

        // Сохраняем ID и имя
        userId = userProfile.id
        name = userProfile.name

        // Сохраняем изображение (если передано)
        if let image = avatarImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            let url = avatarFileURL()
            try? data.write(to: url)
            UserDefaults.standard.set(url.path, forKey: avatarPathKey)
        }
    }

    // MARK: - Logout

    func logout() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: avatarPathKey)

        // Удаляем файл изображения
        let url = avatarFileURL()
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Get

    func getUserProfile() -> UserProfile? {
        guard let savedData = UserDefaults.standard.data(forKey: profileKey) else {
            return nil
        }

        return try? JSONDecoder().decode(UserProfile.self, from: savedData)
    }

    func getAvatarImage() -> UIImage? {
        guard let path = UserDefaults.standard.string(forKey: avatarPathKey) else { return nil }
        let url = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    // MARK: - Helpers

    private func avatarFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar.jpg")
    }
}

// MARK: - Properties

extension UserManager {
    var isFirstLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: isFirstLaunchKey) }
        set { UserDefaults.standard.set(newValue, forKey: isFirstLaunchKey) }
    }
    var userId: String {
        get { UserDefaults.standard.string(forKey: userIdKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }

    var name: String {
        get { UserDefaults.standard.string(forKey: nameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }
}
