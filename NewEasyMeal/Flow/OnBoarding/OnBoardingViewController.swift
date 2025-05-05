import Foundation
import UIKit

struct OnBoardingNavigation {
    let onSucceed: Callback
}

class OnBoardingViewController: UIViewController {
    private let viewModel = OnboardingViewModel()
    private let navigation: OnBoardingNavigation
    
    private lazy var rootView: Bridged = {
        OnboardingView(
            viewModel: viewModel,
            onSucceed: navigation.onSucceed
        ).convertSwiftUIToHosting()
    }()

    init(navigation: OnBoardingNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI(rootView)
    }
}
