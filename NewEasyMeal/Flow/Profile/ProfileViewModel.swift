import Foundation
import UIKit
// MARK: - ViewModel
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: UserProfile?

    init(user: UserProfile?) {
        self.user = user
    }
    
    func getProfile() {
        Task {
            do {
                user = try await APIHelper.shared.fetchProfile()
            } catch {
                print(error)
            }
        }
    }

    // Example action: logout
    func logout() {
        // Implement logout logic
        print("Logout tapped")
    }
}
