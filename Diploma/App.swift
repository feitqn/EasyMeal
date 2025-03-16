import SwiftUI
import FirebaseCore
import GoogleSignIn
import CoreData
import FirebaseMessaging
import UserNotifications
import FirebaseAppCheck

@main
struct EasyMealApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var authService = AuthService.shared
    
    init() {
        // Регистрируем трансформер для массивов строк
        StringArrayValueTransformer.register()
        
        #if DEBUG
        // Отключаем все логи Firebase в debug режиме
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        #endif
        
        // Отключаем аналитику и логи
        UserDefaults.standard.set(false, forKey: "FIRAnalyticsDebugEnabled")
        UserDefaults.standard.set(false, forKey: "FIRAnalyticsVerboseLoggingEnabled")
        UserDefaults.standard.set(false, forKey: "FirebaseAutomaticScreenReportingEnabled")
        
        // Базовая конфигурация Firebase
        FirebaseApp.configure()
        
        // Настраиваем AppCheck
        if #available(iOS 14.0, *) {
            let providerFactory = AppCheckDebugProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        #if targetEnvironment(simulator)
        // Отключаем уведомления для симулятора
        Messaging.messaging().isAutoInitEnabled = false
        #else
        // Настройка уведомлений для реального устройства
        setupNotifications()
        #endif
        
        return true
    }
    
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        DispatchQueue.main.async {
            center.getNotificationSettings { settings in
                guard settings.authorizationStatus != .denied else { return }
                
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    guard granted else { return }
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        let messaging = Messaging.messaging()
                        messaging.delegate = self
                        messaging.isAutoInitEnabled = true
                    }
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        #if DEBUG
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
        }
        #endif
    }
}

// MARK: - Remote Notifications
extension AppDelegate {
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if !targetEnvironment(simulator)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {}
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
} 
