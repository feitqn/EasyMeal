import UIKit

enum TabBarPage {
    case main
    case test
    case unik
    case profile

    init?(index: Int) {
        switch index {
        case 0:
            self = .main
        case 1:
            self = .test
        case 2:
            self = .unik
        default:
            return nil
        }
    }
    
    func pageTitleValue() -> String {
        switch self {
        case .main:
            return "Home"
        case .test:
            return "Recipes"
        case .unik:
            return "Progress"
        case .profile:
            return "Profile"
        }
    }

    func pageOrderNumber() -> Int {
        switch self {
        case .main:
            return 0
        case .test:
            return 1
        case .unik:
            return 2
        case .profile:
            return 3
        }
    }

    func pageImageValue() -> UIImage {
        switch self {
        case .main:
            return UIImage(named: "domic")!
        case .test:
            return UIImage(named: "list")!
        case .unik:
            return UIImage(named: "result")!
        case .profile:
            return UIImage(named: "profile")!
        }
    }
}


protocol TabCoordinatorProtocol: Coordinator {
    var tabBarController: UITabBarController { get set }
    
    func selectPage(_ page: TabBarPage)
    
    func setSelectedIndex(_ index: Int)
    
    func currentPage() -> TabBarPage?
}

class TabCoordinator: NSObject, Coordinator {
    weak var finishDelegate: CoordinatorFinishDelegate?
        
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    
    var tabBarController: UITabBarController

    var type: CoordinatorType { .tab }
    
    required init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.tabBarController = .init()
    }

    func start() {
        // Let's define which pages do we want to add into tab bar
        let pages: [TabBarPage] = [.unik, .test, .main, .profile]
            .sorted(by: { $0.pageOrderNumber() < $1.pageOrderNumber() })
        
        // Initialization of ViewControllers or these pages
        let controllers: [UINavigationController] = pages.map({ getTabController($0) })
        
        prepareTabBarController(withTabControllers: controllers)
    }
    
    deinit {
        print("TabCoordinator deinit")
    }
    
    private func prepareTabBarController(withTabControllers tabControllers: [UIViewController]) {
        /// Set delegate for UITabBarController
        tabBarController.delegate = self
        /// Assign page's controllers
        tabBarController.setViewControllers(tabControllers, animated: true)
        /// Let set index
        tabBarController.selectedIndex = TabBarPage.main.pageOrderNumber()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Изменение фона TabBar
        appearance.backgroundColor = .white
        
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        
        /// Styling
        tabBarController.tabBar.isTranslucent = false
        tabBarController.tabBar.backgroundColor = UIColor(Colors.backColor)
        
        tabBarController.tabBar.barTintColor = UIColor.black
        tabBarController.tabBar.tintColor = UIColor(Colors._7BBF4C)
        tabBarController.tabBar.unselectedItemTintColor = .black
        tabBarController.tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBarController.tabBar.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        tabBarController.tabBar.layer.shadowRadius = 5
        tabBarController.tabBar.layer.shadowOpacity = 0.3
        tabBarController.tabBar.layer.masksToBounds = false
        
        /// In this step, we attach tabBarController to navigation controller associated with this coordanator
        navigationController.viewControllers = [tabBarController]
        
    }
      
    private func getTabController(_ page: TabBarPage) -> UINavigationController {
        let navController = UINavigationController()
        navController.setNavigationBarHidden(false, animated: false)

        navController.tabBarItem = UITabBarItem.init(title: page.pageTitleValue(),
                                                     image:  page.pageImageValue(),
                                                     tag: page.pageOrderNumber())
        navController.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        navController.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 12)

        switch page {
        case .main:
            let mainVC = HomeViewController(navigation: HomeNavigation(onLogout: {}, onTapMeal: { [weak self] meal in
                let vc = LogViewController(
                    navigation: LogViewNavigation(
                        onExitTap: {
                            self?.navigationController.popViewController(animated: true)
                        },
                        onTapAction: {_ in}, onAddTap: { [weak self] food, mealType in
                            self?.presentAddBasket(with: food, and: mealType)
                        }), mealType: meal.mapToMealType())
                self?.navigationController.pushViewController(vc, animated: true)
            }))
            navController.pushViewController(mainVC, animated: true)
        case .test:
            let instVC = RecipesMainViewController()
            instVC.navigationController?.isNavigationBarHidden = true
            navController.pushViewController(instVC, animated: true)
        case .unik:
            let goVC = ProgressOverviewViewController()
            goVC.navigationController?.isNavigationBarHidden = true
            navController.pushViewController(goVC, animated: true)
        case .profile:
            let prof = ProfileViewController(navigation: ProfileNavigation(onLogout: { [weak self] in
                self?.finish()
            }, onTapAction: { [weak self] action in
                self?.handleAction(action)
            }))
            
            navController.pushViewController(prof, animated: true)
        }
        
        return navController
    }
    
    private func presentAddBasket(with food: FoodItem, and mealType: MealType) {
        let vc = AddMealViewController(navigation: AddMealNavigation(onLogout: {}, onTapAction: { _ in}), food: food, mealType: mealType)
        
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom { _ in return 390 }]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        navigationController.present(vc, animated: true)
    }
    
    private func handleAction(_ action: ProfileAction) {
        switch action {
        case .personalInfo:
            let vc = PersonalInfoViewController(navigation: PersonalInfoNavigation(onExitTap: { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }, editAction: {}))
            navigationController.pushViewController(vc, animated: true)
        case .healthGoal:
            let vc = HealthGoalViewController(navigation: HealthGoalNavigation(onExitTap: { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }, editAction: {}))
            navigationController.pushViewController(vc, animated: true)
        case .favourite:
            showComingSoonAlert()
        case .shoppingList:
            let vc = ShoppingListViewController(navigation: ShoppingListNavigation(onLogout: {}, onTapAction: { _ in
                
            }))
            navigationController.pushViewController(vc, animated: true)
        case .notification:
            let vc = NotificationViewController(navigation: NotificationNavigation(onExitTap: { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }, editAction: {}))
            navigationController.pushViewController(vc, animated: true)
        case .faqs:
            let vc = FAQViewController()
            navigationController.pushViewController(vc, animated: true)
        case .contactUs:
            let vc = ContactUsViewController()
            navigationController.pushViewController(vc, animated: true)
        case .settings:
            let vc = SettingsViewController()
            navigationController.pushViewController(vc, animated: true)
        }
    }
    
    private func showComingSoonAlert() {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "This feature will be available in the next release.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true, completion: nil)
    }
    
    func currentPage() -> TabBarPage? { TabBarPage.init(index: tabBarController.selectedIndex) }

    func selectPage(_ page: TabBarPage) {
        tabBarController.selectedIndex = page.pageOrderNumber()
    }
    
    func setSelectedIndex(_ index: Int) {
        guard let page = TabBarPage.init(index: index) else { return }
        
        tabBarController.selectedIndex = page.pageOrderNumber()
    }
}

// MARK: - UITabBarControllerDelegate
extension TabCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController) {
        // Some implementation
    }
}


