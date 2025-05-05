//import Foundation
//import UIKit
//
//protocol ProfileCoordinatorProtocol: Coordinator {
//    func showProfileViewController()
//}
//
//class ProfileCoordinator: ProfileCoordinatorProtocol {
//    weak var finishDelegate: CoordinatorFinishDelegate?
//    
//    var navigationController: UINavigationController
//    
//    var childCoordinators: [Coordinator] = []
//    
//    var type: CoordinatorType { .login }
//        
//    required init(_ navigationController: UINavigationController) {
//        self.navigationController = navigationController
//    }
//        
//    func start() {
//        showProfileViewController()
//    }
//    
//    deinit {
//        print("ProfileCoordinator deinit")
//    }
//    
//    func showProfileViewController() {
//        let profileVC = ProfileViewController(navigation: ProfileNavigation(onExitTap: {
//            
//        }))
//        navigationController.pushViewController(profileVC, animated: true)
//    }
//}
