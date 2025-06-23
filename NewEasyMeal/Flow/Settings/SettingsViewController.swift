import UIKit
import SwiftUI

class SettingsViewController: BaseNavigationTransparentViewController {
    private let viewModel = FAQViewModel()

    private lazy var rootView: Bridged = {
        SettingsView(onNavigateBack: {
            self.navigationController?.popViewController(animated: true)
        }, onUnitsSelected: {
            self.routeToUnits()
        }, onNotificationsSelected: {
            self.routeToNotification()
        }).convertSwiftUIToHosting()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
        
    }
    
    private func routeToUnits() {
        let vc = UnitsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func routeToNotification() {
        let vc = NotificationSettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
