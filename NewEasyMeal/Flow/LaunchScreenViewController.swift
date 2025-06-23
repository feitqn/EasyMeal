import UIKit

class LaunchScreenViewController: UIViewController {
    var onTapGetStarted: (() -> Void)?
    
    private let headerImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "welcomePage"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let button: UIButton = {
        let button = CustomButton(title: "Get Started")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(headerImageView)
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            // headerImageView заполняет весь экран
            headerImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Кнопка находится внизу, на 140pt выше нижнего края
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -140)
        ])
    }
    
    @objc
    private func actionButtonTapped() {
        UserManager.shared.setIsFirstLaunch()
        onTapGetStarted?()
    }
}
