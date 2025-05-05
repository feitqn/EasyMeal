import UIKit
import SwiftUI

extension UIFont {
    static func urbanMedium(size: CGFloat) -> UIFont {
        let font = UIFont(name: "Urbanist-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
        return UIFontMetrics.default.scaledFont(for: font)
    }
    
    static func urban(size: CGFloat) -> UIFont {
        let font = UIFont(name: "Urbanist-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
        return UIFontMetrics.default.scaledFont(for: font)
    }
    
    static func urbanSemiBold(size: CGFloat) -> UIFont {
        let font = UIFont(name: "Urbanist-SemiBold", size: size) ?? UIFont.systemFont(ofSize: size)
        return UIFontMetrics.default.scaledFont(for: font)
    }
    
    static func urbanBold(size: CGFloat) -> UIFont {
        let font = UIFont(name: "Urbanist-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
        return UIFontMetrics.default.scaledFont(for: font)
    }
}

extension Font {
    static func urbanMedium(size: CGFloat) -> Font {
        return Font.custom("Urbanist-Medium", size: size, relativeTo: .body)
    }

    static func urban(size: CGFloat) -> Font {
        return Font.custom("Urbanist-Regular", size: size, relativeTo: .body)
    }

    static func urbanSemiBold(size: CGFloat) -> Font {
        return Font.custom("Urbanist-SemiBold", size: size, relativeTo: .body)
    }
    
    static func urbanBold(size: CGFloat) -> Font {
        return Font.custom("Urbanist-Bold", size: size, relativeTo: .body)
    }
}
