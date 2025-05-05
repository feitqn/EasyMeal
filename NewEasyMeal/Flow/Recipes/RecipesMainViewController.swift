import UIKit
import SwiftUI

class RecipesMainViewController: UIViewController {
    private let viewModel = RecipesMainViewModel()

    private lazy var rootView: Bridged = {
        RecipesMainView(viewModel: viewModel).convertSwiftUIToHosting()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
    }
}
