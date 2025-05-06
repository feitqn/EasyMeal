import UIKit


struct SettingsNavigation {
    var onExitTap: Callback
    var editAction: Callback
}

class SettingsViewController: UIViewController {

    var navigation: SettingsNavigation
    private lazy var rootView: Bridged = {
        SettingView(onTapLogout: {
            self.navigation.onExitTap()
        }, onTapEdit: {
            self.navigation.editAction()
        }, onTapBack: {
            self.navigationController?.popViewController(animated: true)
        }).convertSwiftUIToHosting()
    }()
    
    init(navigation: SettingsNavigation) {
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
    
    func navigate() {

    }
}
