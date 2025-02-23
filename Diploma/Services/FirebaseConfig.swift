import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck

class FirebaseConfig {
    static func configure() {
        // Инициализация Firebase
        FirebaseApp.configure()
        
        // Настройка Firestore
        let settings = Firestore.firestore().settings
        let cacheSize: Int64 = 100 * 1024 * 1024 // 100MB в байтах
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: cacheSize))
        Firestore.firestore().settings = settings
        
        // Отключаем AppCheck для симулятора
        #if targetEnvironment(simulator)
        // Используем Debug Provider для симулятора
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        print("Firebase успешно сконфигурирован")
    }
} 