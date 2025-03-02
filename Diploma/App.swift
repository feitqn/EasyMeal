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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Настройка AppCheck для симулятора
        #if DEBUG
        print("Настройка AppCheck для симулятора")
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        print("Конфигурация Firebase")
        FirebaseApp.configure()
        
        print("Настройка уведомлений")
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    print("Ошибка при запросе разрешений для уведомлений: \(error)")
                } else {
                    print("Разрешения для уведомлений: \(granted ? "получены" : "отклонены")")
                }
            }
        )
        
        print("Регистрация для push-уведомлений")
        application.registerForRemoteNotifications()
        
        print("Настройка Firebase Messaging")
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Push Notification Handling
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Получен APNS токен")
        Messaging.messaging().apnsToken = deviceToken
        
        print("Запрос FCM токена")
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Ошибка получения FCM токена: \(error)")
            } else if let token = token {
                print("FCM токен получен: \(token)")
            }
        }
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Ошибка регистрации для push-уведомлений: \(error)")
    }
    
    func messaging(_ messaging: Messaging,
                  didReceiveRegistrationToken fcmToken: String?) {
        print("Получен новый FCM токен: \(String(describing: fcmToken))")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
} 