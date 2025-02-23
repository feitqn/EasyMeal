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
        return try? NSKeyedArchiver.archivedData(withRootObject: stringArray, requiringSecureCoding: true)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [String]
    }
    
    static func register() {
        let transformer = StringArrayValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName("StringArrayValueTransformer"))
    }
} 