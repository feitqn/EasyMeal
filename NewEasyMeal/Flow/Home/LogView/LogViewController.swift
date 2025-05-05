import UIKit

struct LogViewNavigation {
    var onExitTap: Callback
    var onTapAction: (ProfileAction) -> ()
    var onAddTap: (FoodItem, MealType) -> ()
}

class LogViewController: BaseNavigationTransparentViewController {
    var mealType: MealType
    var navigation: LogViewNavigation

    private lazy var rootView: Bridged = {
        LogView(
            onExitTap: navigation.onExitTap,
            onAddTap: { [weak self] food in
                guard let self else { return }
                self.navigation.onAddTap(food, self.mealType)
            }
        ).convertSwiftUIToHosting()
    }()
    
    init(navigation: LogViewNavigation, mealType: MealType) {
        self.navigation = navigation
        self.mealType = mealType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSwiftUI(rootView)
    }
}
