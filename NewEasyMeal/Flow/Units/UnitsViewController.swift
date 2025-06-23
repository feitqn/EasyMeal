import UIKit
import SwiftUI

class UnitsViewController: BaseNavigationTransparentViewController {
    private let viewModel = FAQViewModel()

    private lazy var rootView: Bridged = {
        UnitsView(onTapExit: {
            self.navigationController?.popViewController(animated: true)
        }).convertSwiftUIToHosting()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
        
    }
}
