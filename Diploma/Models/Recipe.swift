import Foundation
import CoreData

@objc(CDRecipe)
public class CDRecipe: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var imageURL: String
    @NSManaged public var cookingTime: Int32
    @NSManaged public var difficulty: String
    @NSManaged public var calories: Int32
    @NSManaged public var protein: Double
    @NSManaged public var fats: Double
    @NSManaged public var carbs: Double
    @NSManaged public var ingredients: [String]?
    @NSManaged public var steps: [String]?
    @NSManaged public var categoryRawValue: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        ingredients = []
        steps = []
        createdAt = Date()
        updatedAt = Date()
    }
    
    var category: RecipeCategory {
        get {
            RecipeCategory(rawValue: categoryRawValue) ?? .breakfast
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }
}

extension CDRecipe {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDRecipe> {
        return NSFetchRequest<CDRecipe>(entityName: "CDRecipe")
    }
}

// MARK: - Recipe Category
enum RecipeCategory: String, CaseIterable {
    case breakfast = "Завтрак"
    case lunch = "Обед"
    case dinner = "Ужин"
    case snack = "Перекус"
    case kazakh = "Казахская кухня"
    
    var icon: String {
        switch self {
        case .breakfast: return "sun.and.horizon"
        case .lunch: return "sun.max"
        case .dinner: return "moon.stars"
        case .snack: return "leaf"
        case .kazakh: return "house"
        }
    }
    
    var color: String {
        switch self {
        case .breakfast: return "orange"
        case .lunch: return "yellow"
        case .dinner: return "blue"
        case .snack: return "green"
        case .kazakh: return "red"
        }
    }
} 