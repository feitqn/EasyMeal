import Foundation
import SwiftUI

struct Colors {
    static let green = Color(red: 70/255, green: 149/255, blue: 152/255)
    static let gray = Color(#colorLiteral(red: 0.738735795, green: 0.7736777663, blue: 0.8245255351, alpha: 1))
    static let darkBlue = Color(red: 60/255, green: 57/255, blue: 186/255).opacity(1)
    static let tabBarBack = Color(red: 83/255, green: 124/255, blue: 198/255).opacity(1)
    static let purple = Color(red: 60/255, green: 57/255, blue: 186/255)
    static let backColor = Color.white
    static let labelColor = Color.black
    static let strokeColor = Color(red: 146/255, green: 183/255, blue: 117/255)
    static let greenColor = Color(#colorLiteral(red: 0, green: 0.7318587899, blue: 0.3746651113, alpha: 1))
    static let gradientColor = Color(#colorLiteral(red: 0, green: 0.5085113645, blue: 0.2016089261, alpha: 1))
    static let mainTextColor = Color(#colorLiteral(red: 0.2843993902, green: 0.3348659873, blue: 0.3937162757, alpha: 1))
    static let lightGreen = Color(#colorLiteral(red: 0.7772397399, green: 0.9864136577, blue: 0.8925992846, alpha: 1))
    static let _E8ECF4 = Color(hex: "#E8ECF4")
    static let _F7F8F9 = Color(hex: "#F7F8F9")
    static let _9FE860 = Color(hex: "#9FE860")
    static let _50CE3B = Color(hex: "#50CE3B")
    static let _6A6A6A = Color(hex: "#6A6A6A")
    static let _7BBF4C = Color(hex: "#7BBF4C")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = (
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17,
                255
            )
        case 6: // RGB (24-bit)
            (r, g, b, a) = (
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF,
                255
            )
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (r, g, b, a) = (1, 1, 1, 1)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

//extension UIColor {
//    convenience init(_ color: Color) {
//        let scanner = Scanner(string: color.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
//        var hexNumber: UInt64 = 0
//        let r, g, b, a: CGFloat
//
//        if scanner.scanHexInt64(&hexNumber) {
//            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
//            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
//            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
//            a = CGFloat(hexNumber & 0x000000ff) / 255
//        } else {
//            r = 1
//            g = 1
//            b = 1
//            a = 1
//        }
//
//        self.init(red: r, green: g, blue: b, alpha: a)
//    }
//}
