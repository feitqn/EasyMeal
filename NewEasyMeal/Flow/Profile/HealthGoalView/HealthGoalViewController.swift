import UIKit

struct HealthGoalNavigation {
    var onExitTap: Callback
    var editAction: Callback
}

class HealthGoalViewController: BaseNavigationTransparentViewController {
    private let navigation: HealthGoalNavigation
    
    private let viewModel = HealthGoalsViewModel()
    
    private lazy var rootView: Bridged = {
        HealthGoalsView(viewModel: viewModel, onTapExit: { [weak self] in
            self?.navigation.onExitTap()
        }).convertSwiftUIToHosting()
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
