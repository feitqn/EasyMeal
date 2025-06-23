import UIKit
import SwiftUI
import GoogleSignIn
import FirebaseAuth

typealias Callback = () -> ()

struct LoginNavigation {
    var onSucceedLogin: Callback
    var onRegisterTap: Callback
    var onGoogleRegisterTap: Callback
}

typealias Bridged = UIViewController

class LoginViewController: UIViewController {

    private let navigation: LoginNavigation
    private var viewModel = LoginViewModel()
    
    private lazy var loginView: Bridged = {
        LoginView(viewModel: viewModel, 
                  onButtonTapped: { [weak self] email, pass in
            self?.viewModel.login(email: email, password: pass, completion: {
                    self?.navigation.onSucceedLogin()
            })
        }, onRegisterTapped: { [weak self] in
            self?.navigation.onRegisterTap()
        }, onGoogleTapped: { [weak self] in
            self?.googleLogin()
        }).convertSwiftUIToHosting()
    }()
    
    
    init(navigation: LoginNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI(loginView)
    }
    
    deinit {
        print("LoginViewController deinit")
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
                        print("Это регистрация")
                        self.navigation.onGoogleRegisterTap()
                    } else {
                        self.navigation.onSucceedLogin()
                        print("Это логин")
                    }
                }
            }
    }
}
