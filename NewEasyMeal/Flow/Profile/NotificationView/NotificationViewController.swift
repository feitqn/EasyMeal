import UIKit
//import SkeletonView

struct NotificationNavigation {
    var onExitTap: Callback
    var editAction: Callback
}

class NotificationViewController: BaseNavigationTransparentViewController {
    private let navigation: NotificationNavigation
    
    private lazy var rootView: Bridged = {
        NotificationView().convertSwiftUIToHosting()
    }()
    
    init(navigation: NotificationNavigation) {
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
