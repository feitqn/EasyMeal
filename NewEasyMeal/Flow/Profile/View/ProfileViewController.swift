import UIKit

enum ProfileAction {
    case personalInfo
    case healthGoal
    case favourite
    case shoppingList
    case notification
    case faqs
    case contactUs
    case settings
}

struct ProfileNavigation {
    var onLogout: Callback
    var onTapAction: (ProfileAction) -> ()
}

class ProfileViewController: UIViewController {
    var navigation: ProfileNavigation
    
    var viewModel = ProfileViewModel(user: UserManager.shared.getUserProfile())
    
    var profileItems: [ProfileOption] = [
        .init(icon: "person", title: "Personal Info", action: .personalInfo),
        .init(icon: "flag", title: "Health Goal", action: .healthGoal)
    ]
    
    var servicesItems: [ProfileOption] = [
        .init(icon: "heart", title: "Favourite Recipes", action: .favourite),
        .init(icon: "list.bullet", title: "Shopping List", action: .shoppingList),
        .init(icon: "bell", title: "Notification", action: .notification)
    ]
    
    var supportItems: [ProfileOption] = [
        .init(icon: "questionmark.circle", title: "FAQs", action: .faqs),
        .init(icon: "phone", title: "Contact Us", action: .contactUs),
        .init(icon: "gear", title: "Settings", action: .settings)
    ]
    
    private lazy var rootView: Bridged = {
        ProfileView(viewModel: viewModel, profileItems: profileItems,
                    servicesItems: servicesItems,
                    supportItems: supportItems,
                    navigation: ProfileNavigation(
                        onLogout: { [weak self] in
                            self?.presentLogoutConfirmationAlert()
                        },
                        onTapAction: { [weak self] action in
                            self?.didTapAction(action)
                        }
                    )).convertSwiftUIToHosting()
    }()
    
    init(navigation: ProfileNavigation) {
        self.navigation = navigation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupSwiftUI(rootView)
    }
    
    private func didTapAction(_ action: ProfileAction) {
        navigation.onTapAction(action)
    }
    
    func navigate() {
//        let vc = OnBoardingViewController(navigation: OnBoardingNavigation(onExit: {
//            self.navigationController?.popViewController(animated: true)
//        }), viewModel: OnBoardingViewModel(profile: viewModel.profile))
//        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func navigateToSettings() {
//        guard let profile = viewModel.profile else {return}
//        let vc = SettingsViewController(profile: profile,
//                                        navigation: ProfileNavigation(onExitTap: {
//            self.navigation.onExitTap()
//        }, editAction: {
//            self.navigate()
//        }))
//        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    deinit {
        print("ProfileViewController deinit")
    }
    
    func presentLogoutConfirmationAlert() {
        let alert = UIAlertController(
            title: "Are you sure?",
            message: "Do you really want to log out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }

            // Создаем и презентуем alert
            let loadingAlert = self.makeLoadingAlert(message: "Logging out...")
            self.present(loadingAlert, animated: true)

            // logout завершится — dismiss loading alert и навигация
            APIHelper.shared.logout { [weak self] in
                guard let self = self else { return }

                // dismiss отдельно
                self.dismiss(animated: true) {
                    self.navigation.onLogout()
                }
            }
        }))
        
        present(alert, animated: true)
    }
    
    func makeLoadingAlert(message: String = "Please wait...") -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "\(message)\n\n", preferredStyle: .alert)

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()

        alert.view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20)
        ])

        return alert
    }
    
    private func didTapAddImage() {
        let alertSheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        alertSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.createImagePickerController(sourceType: .camera)
            } else {
                print("Camera not available.")
            }
        }))
        alertSheet.addAction(UIAlertAction(title: "Open Gallery", style: .default, handler: { _ in
            self.createImagePickerController(sourceType: .photoLibrary)
        }))
        alertSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertSheet, animated: true)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        if let selectedImage = info[.originalImage] as? UIImage {
//            viewModel.image = selectedImage
//            viewModel.imageURL = ""
//            viewModel.updateAvatar()
//        }
//        picker.dismiss(animated: true, completion: nil)
    }
    
    func createImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
}
