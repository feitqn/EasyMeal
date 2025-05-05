import UIKit
import SwiftUI

typealias Callback = () -> ()

struct LoginNavigation {
    var onSucceedLogin: Callback
    var onRegisterTap: Callback
}

typealias Bridged = UIViewController

class LoginViewController: UIViewController {

    private let navigation: LoginNavigation
    private var viewModel = LoginViewModel()
    
    private lazy var loginView: Bridged = {
        LoginView(viewModel: viewModel, 
                  onButtonTapped: { [weak self] email, pass in
            self?.viewModel.login(email: email, password: pass, completion: {
                    self?.navigation.onSucceedLogin()
            })
        }, onRegisterTapped: { [weak self] in
            self?.navigation.onRegisterTap()
        }).convertSwiftUIToHosting()
    }()
    
    
    init(navigation: LoginNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI(loginView)
    }
    
    deinit {
        print("LoginViewController deinit")
    }
}
