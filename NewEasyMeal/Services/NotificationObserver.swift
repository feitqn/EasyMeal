import UIKit

final class NotificationObserver {
    private var observer: NSObjectProtocol?
    
    init(notificationName: Notification.Name,
         object: Any? = nil,
         queue: OperationQueue? = .main,
         using block: @escaping (Notification) -> Void) {
        observer = NotificationCenter.default.addObserver(
            forName: notificationName,
            object: object,
            queue: queue,
            using: block
        )
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
