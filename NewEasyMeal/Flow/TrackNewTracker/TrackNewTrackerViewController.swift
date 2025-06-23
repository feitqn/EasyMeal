import UIKit
import SwiftUI

class TrackNewTrackerViewController: UIViewController {
    private let viewModel = TrackerViewModel()

    private lazy var rootView: Bridged = {
        TrackerSelectionView(buttonTapped: { [weak self] in
            self?.viewModel.addTracker {
                self?.dismiss(animated: true)
            }
        }, viewModel: viewModel)
            .convertSwiftUIToHosting()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
    }
}
