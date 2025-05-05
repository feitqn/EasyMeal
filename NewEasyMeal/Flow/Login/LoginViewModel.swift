import Foundation

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var error: String = ""
    
    func login(email: String, password: String, completion: @escaping Callback) {
        guard checkForValidness() else { return }

        Task {
            do {
                let response = try await APIHelper.shared.login(email: email, password: password)
                
                let userProfile = try await APIHelper.shared.fetchUserProfile(for: response.uid)
                UserManager.shared.save(userProfile: userProfile)
                
                await MainActor.run {
                    completion()
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func checkForValidness() -> Bool {
        if !email.isValidEmail() {
            self.error = "Введите правильный email"
            return false
        }
        return true
    }
}
