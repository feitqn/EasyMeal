import SwiftUI

struct CustomButtonView: UIViewRepresentable {
    var title: String
    var action: () -> Void
    
    func makeUIView(context: Context) -> CustomButton {
        let button = CustomButton(title: title)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: CustomButton, context: Context) {
        // Если нужно обновлять кнопку
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func didTapButton() {
            action()
        }
    }
}
