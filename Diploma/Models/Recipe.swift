import Foundation
import CoreData

@objc(Recipe)
public class Recipe: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var imageURL: String?
    @NSManaged public var cookingTime: Int32
    @NSManaged public var difficulty: String
    @NSManaged public var calories: Int32
    @NSManaged public var protein: Double
    @NSManaged public var fats: Double
    @NSManaged public var carbs: Double
    @NSManaged private var ingredientsArray: NSArray?
    @NSManaged private var stepsArray: NSArray?
    @NSManaged public var categoryRawValue: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        ingredientsArray = []
        stepsArray = []
        createdAt = Date()
        updatedAt = Date()
        categoryRawValue = RecipeCategory.breakfast.rawValue
    }
    
    var ingredients: [String]? {
        get {
            ingredientsArray as? [String]
        }
        set {
            ingredientsArray = newValue as NSArray?
        }
    }
    
    var steps: [String]? {
        get {
            stepsArray as? [String]
        }
        set {
            stepsArray = newValue as NSArray?
        }
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

extension Recipe {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recipe> {
        return NSFetchRequest<Recipe>(entityName: "Recipe")
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
