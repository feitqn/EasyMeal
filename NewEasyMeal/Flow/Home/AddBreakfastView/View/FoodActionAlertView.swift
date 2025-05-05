import UIKit

enum FoodActionResultType {
    case success
    case failure
}

final class FoodActionAlertView: UIView {

    // MARK: - Public

    var type: FoodActionResultType {
        didSet {
            configureContent()
        }
    }

    // MARK: - UI

    private lazy var iconImageView = makeIconImageView()
    private lazy var titleLabel = makeTitleLabel()
    private lazy var subtitleLabel = makeSubtitleLabel()

    // MARK: - Init

    init(type: FoodActionResultType) {
        self.type = type
        super.init(frame: .zero)
        setup()
        configureContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 5)

        let stack = makeView()
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    private func makeView() -> UIStackView {
        let spacing1 = UIView()
        spacing1.translatesAutoresizingMaskIntoConstraints = false
        spacing1.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let spacing2 = UIView()
        spacing2.translatesAutoresizingMaskIntoConstraints = false
        spacing2.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let stack = UIStackView(arrangedSubviews: [
            iconImageView,
            spacing1,
            titleLabel,
            spacing2,
            subtitleLabel
        ])
        stack.axis = .vertical
        stack.alignment = .center
        return stack
    }

    private func makeIconImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return imageView
    }

    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }

    private func makeSubtitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    // MARK: - Configuration

    private func configureContent() {
        switch type {
        case .success:
            iconImageView.image = UIImage(systemName: "hand.thumbsup.fill")?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = .systemYellow
            titleLabel.text = "Successfully Added!"
            subtitleLabel.text = "Breakfast updated — keep going!"

        case .failure:
            iconImageView.image = UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = .systemRed
            titleLabel.text = "Failed to Add Food!"
            subtitleLabel.text = "Please try again later."
        }
    }
}
