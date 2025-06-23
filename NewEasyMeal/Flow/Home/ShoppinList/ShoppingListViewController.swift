import UIKit

struct ShoppingListNavigation {
    var onLogout: Callback
    var onTapAction: (ProfileAction) -> ()
}

class ShoppingListViewController: BaseNavigationTransparentViewController {
    var navigation: ShoppingListNavigation
    var viewModel = FoodViewModel()
    
    private lazy var rootView: Bridged = {
        ShoppingListView(viewModel: self.viewModel, onTapBackButton: {
            self.navigationController?.popViewController(animated: true)
        }).convertSwiftUIToHosting()
    }()
    
    init(navigation: ShoppingListNavigation) {
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
        
        viewModel.fetchFoodItems()
    }
}
