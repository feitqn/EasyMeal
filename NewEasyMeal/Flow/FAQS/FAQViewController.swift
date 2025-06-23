import UIKit
import SwiftUI

class FAQViewController: BaseNavigationTransparentViewController {
    private let viewModel = FAQViewModel()

    private lazy var rootView: Bridged = {
        FAQView().convertSwiftUIToHosting()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
        
    }
}
