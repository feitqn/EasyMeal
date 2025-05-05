import UIKit
import SwiftUI

struct RegisterNavigation {
    var onSucceedRegister: Callback
    var onLoginTap: Callback
}

class RegisterViewController: UIViewController {
        
    private var viewModel = RegisterViewModel()
    
    private var navigation: RegisterNavigation
    
    private lazy var rootView: Bridged = {
        RegisterView(viewModel: viewModel, 
                     action: {
            self.navigation.onLoginTap()
        }, completion: {
            self.navigation.onSucceedRegister()
        }).convertSwiftUIToHosting()
    }()
    
    init(navigation: RegisterNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI(rootView)
    }
    
    deinit {
        print("RegisterViewController deinit")
    }
}
