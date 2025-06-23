import UIKit

struct AddMealNavigation {
    var onLogout: Callback
    var onTapAction: (ProfileAction) -> ()
}

class AddMealViewController: UIViewController {
    var foodItem: FoodItem
    var mealType: MealType
    var navigation: AddMealNavigation
    
    private lazy var rootView: Bridged = {
        AddMealView(food: foodItem, onAddTap: {
            self.addItem()
        }).convertSwiftUIToHosting()
    }()
    
    init(navigation: AddMealNavigation, food: FoodItem, mealType: MealType) {
        self.navigation = navigation
        self.foodItem = food
        self.mealType = mealType
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
    
    private func addItem() {
        Task {
            try await APIHelper.shared.addMeal(for: mealType, and: foodItem)
            await MainActor.run {
                showFoodActionAlert(type: .success)
                NotificationCenter.default.post(name: .getProfile, object: self)
            }
        }
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
