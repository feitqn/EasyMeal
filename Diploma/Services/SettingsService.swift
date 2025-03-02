import Foundation
import Combine

class SettingsService: ObservableObject {
    static let shared = SettingsService()
    
    private let defaults = UserDefaults.standard
    
    @Published var waterNotificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "waterNotificationsEnabled")
    @Published var mealNotificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "mealNotificationsEnabled")
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let isFirstLaunch = "isFirstLaunch"
        static let notificationsEnabled = "notificationsEnabled"
        static let waterNotificationsEnabled = "waterNotificationsEnabled"
        static let mealNotificationsEnabled = "mealNotificationsEnabled"
        static let theme = "theme"
        static let language = "language"
        static let isDarkModeEnabled = "isDarkModeEnabled"
        static let measurementSystem = "measurementSystem"
        static let lastSyncDate = "lastSyncDate"
    }
    
    // MARK: - First Launch
    var isFirstLaunch: Bool {
        get { defaults.bool(forKey: Keys.isFirstLaunch) }
        set { defaults.set(newValue, forKey: Keys.isFirstLaunch) }
    }
    
    // MARK: - Notifications
    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Keys.notificationsEnabled) }
        set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }
    
    // MARK: - Theme
    enum Theme: String {
        case light
        case dark
        case system
    }
    
    var theme: Theme {
        get {
            if let themeString = defaults.string(forKey: Keys.theme) {
                return Theme(rawValue: themeString) ?? .system
            }
            return .system
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.theme) }
    }
    
    // MARK: - Language
    enum Language: String {
        case russian = "ru"
        case english = "en"
    }
    
    var language: Language {
        get {
            if let languageString = defaults.string(forKey: Keys.language) {
                return Language(rawValue: languageString) ?? .russian
            }
            return .russian
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.language) }
    }
    
    // MARK: - User Settings
    
    var isDarkModeEnabled: Bool {
        get { defaults.bool(forKey: Keys.isDarkModeEnabled) }
        set { defaults.set(newValue, forKey: Keys.isDarkModeEnabled) }
    }
    
    var measurementSystem: MeasurementSystem {
        get {
            if let rawValue = defaults.string(forKey: Keys.measurementSystem) {
                return MeasurementSystem(rawValue: rawValue) ?? .metric
            }
            return .metric
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.measurementSystem) }
    }
    
    // MARK: - App Settings
    
    var lastSyncDate: Date? {
        get { defaults.object(forKey: Keys.lastSyncDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastSyncDate) }
    }
    
    // MARK: - Reset
    func resetAllSettings() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }
    
    func toggleWaterNotifications(_ enabled: Bool) {
        waterNotificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "waterNotificationsEnabled")
    }
    
    func toggleMealNotifications(_ enabled: Bool) {
        mealNotificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "mealNotificationsEnabled")
    }
    
    func clearAllSettings() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }
}

enum MeasurementSystem: String {
    case metric = "metric"
    case imperial = "imperial"
} 