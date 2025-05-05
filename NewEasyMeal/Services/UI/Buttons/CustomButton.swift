import UIKit

final class CustomButton: UIButton {
    private var gradientLayer: CAGradientLayer?
    
    init(title: String) {
        super.init(frame: .zero)
        setup(title: title, colors: [UIColor(Colors._9FE860), UIColor(Colors._50CE3B)])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "", colors: [])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 60)
    }
    
    private func setup(title: String, colors: [UIColor]) {
        self.setTitle(title, for: .normal)
        self.setTitleColor(.white, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        
        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.insertSublayer(gradient, at: 0)
        self.gradientLayer = gradient
    }
}
