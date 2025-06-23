
import Foundation
import UIKit
import SwiftUI
import Charts

class ProgressOverviewViewController: UIViewController {
    private let viewModel = ProgressOverviewViewModel()
    
    private lazy var rootView: Bridged = {
        ProgressOverviewView(viewModel: viewModel)
            .convertSwiftUIToHosting()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI(rootView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.getFoodDiary()
    }
}

// MARK: - Color Extensions
extension Color {
    static let backColor = Color(UIColor.systemGray6)
}
