import UIKit
import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var appCoordinator: AppCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        window = UIWindow.init(frame: UIScreen.main.bounds)
        
        let navigationController: UINavigationController = .init()

        window?.rootViewController = navigationController
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        
        appCoordinator = AppCoordinator.init(navigationController)
        appCoordinator?.start()
        
        FirebaseApp.configure()
                
        return true
    }
}
