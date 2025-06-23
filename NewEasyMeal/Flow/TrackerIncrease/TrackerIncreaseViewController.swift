import UIKit
import SwiftUI

class TrackerIncreaseViewController: UIViewController {
    private let viewModel = TrackerBottomSheetViewModel()

    private let selectedType: TrackerData
        
    private lazy var rootView: Bridged = {
        TrackerBottomSheet(viewModel: viewModel).convertSwiftUIToHosting()
    }()

    init(selectedType: TrackerData) {
        self.selectedType = selectedType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
        
        viewModel.presentTracker(selectedType)
        
        viewModel.onFinish = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        NotificationCenter.default.post(name: .shouldFetchHomeData, object: nil)
        NotificationCenter.default.post(name: .getProfile, object: nil)
    }
}
