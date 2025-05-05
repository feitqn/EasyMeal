import UIKit
//import SkeletonView

struct PersonalInfoNavigation {
    var onExitTap: Callback
    var editAction: Callback
}

class PersonalInfoViewController: BaseNavigationTransparentViewController {
    private let navigation: PersonalInfoNavigation
    
    private lazy var rootView: Bridged = {
        PersonalInfoView().convertSwiftUIToHosting()
    }()
    
    init(navigation: PersonalInfoNavigation) {
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
