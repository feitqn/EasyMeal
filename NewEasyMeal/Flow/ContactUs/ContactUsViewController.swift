import UIKit
import SwiftUI

class ContactUsViewController: BaseNavigationTransparentViewController {
    private let viewModel = RecipesMainViewModel()

    private lazy var rootView: Bridged = {
        ContactUsView().convertSwiftUIToHosting()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
        
    }
}
