import UIKit
import SwiftUI

class RecipesMainViewController: UIViewController {
    private let viewModel = RecipesMainViewModel()

    private lazy var rootView: Bridged = {
        RecipesMainView(viewModel: viewModel, onTapAdded: {
            self.showFoodActionAlert(type: .success)
        }, onTapShoppingList: {
            self.showShoppingList()
        }).convertSwiftUIToHosting()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
        
//        viewModel.loadMockData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.loadMockData()
    }
    
    private func showShoppingList() {
        let shoppingListViewController = ShoppingListViewController(navigation: ShoppingListNavigation(onLogout: {}, onTapAction: {_ in}))
        navigationController?.pushViewController(shoppingListViewController, animated: true)
    }
    
    private func showFoodActionAlert(type: FoodActionResultType) {
        guard let window = view.window else { return }
        
        let alertView = FoodActionAlertView(type: type)
        alertView.translatesAutoresizingMaskIntoConstraints = false
        alertView.alpha = 0
        alertView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)

        window.addSubview(alertView)

        NSLayoutConstraint.activate([
            alertView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            alertView.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            alertView.alpha = 1
            alertView.transform = .identity
        }, completion: { _ in
            // Автоудаление через 2 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIView.animate(withDuration: 0.2, animations: {
                    alertView.alpha = 0
                }, completion: { _ in
                    alertView.removeFromSuperview()
                })
            }
        })
    }
}
