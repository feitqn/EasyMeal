import UIKit
import SwiftUI
import GoogleSignIn
import FirebaseAuth

struct RegisterNavigation {
    var onSucceedRegister: Callback
    var onLoginTap: Callback
    var onTapLoginGoogle: Callback
}

class RegisterViewController: UIViewController {
        
    private var viewModel = RegisterViewModel()
    
    private var navigation: RegisterNavigation
    
    private lazy var rootView: Bridged = {
        RegisterView(viewModel: viewModel, 
                     action: {
            self.navigation.onLoginTap()
        }, completion: {
            self.navigation.onSucceedRegister()
        }, onGoogleTapped: {
            self.googleLogin()
        }).convertSwiftUIToHosting()
    }()
    
    init(navigation: RegisterNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI(rootView)
    }
    
    deinit {
        print("RegisterViewController deinit")
    }
    
    private func googleLogin() {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: (UIApplication.shared.windows.first?.rootViewController)!) { signInResult, error in
                guard let result = signInResult else { return }
                guard let idToken = result.user.idToken?.tokenString else { return }

                let accessToken = result.user.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: accessToken)

                Auth.auth().signIn(with: credential) { authResult, error in
                    guard let authResult = authResult else {
                        print("Error signing in: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
 
                    let profile = UserProfile(
                        id: authResult.user.uid,
                        name: result.user.profile?.email.components(separatedBy: "@").first ?? "",
                        email: result.user.profile?.email ?? "",
                        height: 172,
                        weight: 70,
                        gender: "male",
                        currentGoal: "lose",
                        targetWeight: 65
                    )
                    
                    UserManager.shared.save(userProfile: profile)

                    let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false

                    if isNewUser {
                        self.navigation.onSucceedRegister()
                    } else {
                        self.navigation.onLoginTap()
                    }
                }
            }
    }
}
