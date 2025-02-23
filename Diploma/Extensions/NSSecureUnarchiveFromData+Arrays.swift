import Foundation

@objc(StringArrayValueTransformer)
final class StringArrayValueTransformer: NSSecureUnarchiveFromDataTransformer {
    
    static let name = NSValueTransformerName(rawValue: "StringArrayValueTransformer")
    
    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, NSString.self]
    }
    
    public static func register() {
        guard !ValueTransformer.valueTransformerNames().contains(name) else { return }
        let transformer = StringArrayValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
} 