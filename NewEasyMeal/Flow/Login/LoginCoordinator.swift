import Foundation
import UIKit

protocol LoginCoordinatorProtocol: Coordinator {
    func showLoginViewController()
}

class LoginCoordinator: LoginCoordinatorProtocol {
    weak var finishDelegate: CoordinatorFinishDelegate?
    
    var navigationController: UINavigationController
    
    var childCoordinators: [Coordinator] = []
    
    var type: CoordinatorType { .login }
        
    required init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
        
    func start() {
        showLoginViewController()
    }
    
    deinit {
        print("LoginCoordinator deinit")
    }
    
    func showLoginViewController() {
        let loginVC = LoginViewController(navigation: LoginNavigation(onSucceedLogin: {
            self.finish()
        }, onRegisterTap: {
            self.runRegister()
        }))
        
        navigationController.pushViewController(loginVC, animated: true)
    }
    
    func runRegister() {
        let rg = RegisterViewController(navigation: RegisterNavigation(onSucceedRegister: {
            self.runOnboarding()
        }, onLoginTap: {
            self.navigationController.popViewController(animated: true)
        }))
        navigationController.pushViewController(rg, animated: true)
    }
    
    func runOnboarding() {
        let rg = OnBoardingViewController(navigation: OnBoardingNavigation(onSucceed: {
            self.finish()
        }))
        
        navigationController.pushViewController(rg, animated: true)
    }
}
