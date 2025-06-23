
import UIKit
import SwiftUI

class SelectGoalViewController: UIViewController {
    private let viewModel = SelectGoalViewModel()

    private lazy var rootView: Bridged = {
        SelectGoalView(viewModel: viewModel).convertSwiftUIToHosting()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
    }
}
