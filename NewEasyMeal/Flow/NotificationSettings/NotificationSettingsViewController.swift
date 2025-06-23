import UIKit

class NotificationSettingsViewController: BaseNavigationTransparentViewController {
    private let viewModel = HealthGoalsViewModel()
    
    private lazy var rootView: Bridged = {
        NotificationSettingsView(onTapExit: {
            self.navigationController?.popViewController(animated: true)
        }).convertSwiftUIToHosting()
    }()
    
//    init {
//        self.navigation = navigation
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        nil
//    }
//    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
    }
    
}
