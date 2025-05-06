import UIKit


struct HealthGoalNavigation {
    var onExitTap: Callback
    var editAction: Callback
}

class HealthGoalViewController: BaseNavigationTransparentViewController {
    private let navigation: HealthGoalNavigation
    
    private lazy var rootView: Bridged = {
        HealthGoalsView().convertSwiftUIToHosting()
    }()
    
    init(navigation: HealthGoalNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
    }
    
}
