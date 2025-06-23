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
            },
            onTapAddNewTracker: { [weak self] in
                self?.showTrackerView()
            },
            onTapNotification: { [weak self] in
                self?.showNotification()
            },
            onTapTracker: { [weak self] type in
                self?.showTrackerIncreasView(type)
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
        
        fetchObserver = NotificationObserver(notificationName: .getProfile) { [weak self] _ in
            self?.viewModel.fetchFoodDiary()
        }
        fetchObserver = NotificationObserver(notificationName: .shouldFetchHomeData) { [weak self] _ in
            self?.viewModel.fetchFoodDiary()
        }
    }
    
    private func showNotification() {
        let vc = NotificationViewController(navigation: NotificationNavigation(onExitTap: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }, editAction: {}))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showTrackerView() {
        let vc = TrackNewTrackerViewController()
        present(vc, animated: true)
    }
    
    private func showTrackerIncreasView(_ tracker: TrackerData) {
        let vc = TrackerIncreaseViewController(selectedType: tracker)
        present(vc, animated: true)
    }
    
    private func showComingSoonAlert() {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "This feature will be available in the next release.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
