import Foundation
import SwiftUI

extension View {
    func convertSwiftUIToHosting() -> UIHostingController<Self>{
        return UIHostingController(rootView: self)
    }
}
