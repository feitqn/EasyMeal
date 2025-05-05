import Foundation
import UIKit
import SwiftUI
import Charts

class ResultsViewController: UIViewController {
    var viewModel: ResultsViewModel
    
    private lazy var rootView: Bridged = {
        ResultsView()
            .environmentObject(viewModel)
            .convertSwiftUIToHosting()
    }()
    
    init(viewModel: ResultsViewModel = ResultsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ResultsViewModel()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI(rootView)
    }
}

// MARK: - Color Extensions
extension Color {
    static let backColor = Color(UIColor.systemGray6)
}

// MARK: - Preview
struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView()
    }
}
