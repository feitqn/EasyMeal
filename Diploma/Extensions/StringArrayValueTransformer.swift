import Foundation

@objc(StringArrayValueTransformer)
class StringArrayValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let stringArray = value as? [String] else { return nil }
        return try? JSONSerialization.data(withJSONObject: stringArray)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String]
    }
    
    static func register() {
        let name = NSValueTransformerName("StringArrayValueTransformer")
        let transformer = StringArrayValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
} 