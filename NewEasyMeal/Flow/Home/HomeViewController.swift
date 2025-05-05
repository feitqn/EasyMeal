import UIKit

struct HomeNavigation {
    var onLogout: Callback
    var onTapMeal: ((Meal) -> ())?
}

class HomeViewController: UIViewController {
    private var fetchObserver: NotificationObserver?

    private let viewModel = HomeViewModel()
    private let navigation: HomeNavigation

    private lazy var rootView: Bridged = {
        HomeView(
            viewModel: viewModel,
            onSelectMeal: { [weak self] meal in
                self?.navigation.onTapMeal?(meal)
            }
        ).convertSwiftUIToHosting()
    }()
    
    init(navigation: HomeNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
        
        viewModel.fetchFoodDiary()
        
        fetchObserver = NotificationObserver(notificationName: .shouldFetchHomeData) { [weak self] _ in
            self?.viewModel.fetchFoodDiary()
        }
    }
}
