import Foundation
import UIKit
// MARK: - ViewModel
class ProfileViewModel: ObservableObject {
    @Published var user: UserProfile?

    init(user: UserProfile?) {
        self.user = user
    }

    // Example action: logout
    func logout() {
        // Implement logout logic
        print("Logout tapped")
    }
}
