import Foundation

class RegisterViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var telephone: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    
    
    func register(callback: @escaping Callback) {
        guard isValidRegistration() else {
            return
        }

        Task {
            do {
                let response = try await APIHelper.shared.register(name: name, email: email, password: password)
                
                let profile = UserProfile(
                    id: response.uid,
                    name: response.displayName ?? "",
                    email: email,
                    height: 172,
                    weight: 70,
                    gender: "male",
                    currentGoal: "lose",
                    targetWeight: 65
                )
                UserManager.shared.save(userProfile: profile)
                
                try await APIHelper.shared.saveProfile(with: profile)

                await MainActor.run {
                    callback()
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func isValidRegistration() -> Bool {
        errorMessage = ""
        if name.isEmpty || email.isEmpty || password.isEmpty {
            errorMessage = "Please fil all the forms"
            return false
        } else if !email.isValidEmail() {
            errorMessage = "This is not valid email"
            return false
        }
        return true
    }
}
