import Foundation
import CoreData

enum MealType: String, CaseIterable {
    case breakfast = "Завтрак"
    case lunch = "Обед"
    case snack = "Перекус"
    case dinner = "Ужин"
    
    var icon: String {
        switch self {
        case .breakfast: return "sun.rise"
        case .lunch: return "sun.max"
        case .snack: return "leaf"
        case .dinner: return "moon.stars"
        }
    }
    
    var targetCalories: Int {
        switch self {
        case .breakfast: return 653 // 30% от дневной нормы
        case .lunch: return 870 // 40% от дневной нормы
        case .snack: return 109 // 5% от дневной нормы
        case .dinner: return 544 // 25% от дневной нормы
        }
    }
    
    var recommendedTime: DateComponents {
        switch self {
        case .breakfast: return DateComponents(hour: 8, minute: 0)
        case .lunch: return DateComponents(hour: 13, minute: 0)
        case .snack: return DateComponents(hour: 16, minute: 0)
        case .dinner: return DateComponents(hour: 19, minute: 0)
        }
    }
}

@objc(Meal)
public class Meal: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var type: String
    @NSManaged public var calories: Int32
    @NSManaged public var date: Date
    @NSManaged public var products: Set<Product>?
    @NSManaged public var user: User?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID().uuidString
        date = Date()
    }
    
    var mealType: MealType {
        get {
            MealType(rawValue: type) ?? .breakfast
        }
        set {
            type = newValue.rawValue
        }
    }
    
    // Вычисляемые свойства для макронутриентов
    var totalProtein: Double {
        products?.reduce(0) { $0 + $1.protein } ?? 0
    }
    
    var totalFats: Double {
        products?.reduce(0) { $0 + $1.fats } ?? 0
    }
    
    var totalCarbs: Double {
        products?.reduce(0) { $0 + $1.carbs } ?? 0
    }
    
    // Методы для работы с продуктами
    func addProduct(_ product: Product) {
        var currentProducts = products ?? Set<Product>()
        currentProducts.insert(product)
        products = currentProducts
        updateCalories()
    }
    
    func removeProduct(_ product: Product) {
        var currentProducts = products ?? Set<Product>()
        currentProducts.remove(product)
        products = currentProducts
        updateCalories()
    }
    
    private func updateCalories() {
        calories = Int32(products?.reduce(0) { $0 + Int($1.calories) } ?? 0)
    }
    
    // Проверка на превышение рекомендуемых значений
    var isOverCalories: Bool {
        Int(calories) > mealType.targetCalories
    }
    
    var isOverProtein: Bool {
        totalProtein > Double(mealType.targetCalories) * 0.3 / 4 // 30% калорий из белков
    }
    
    var isOverFats: Bool {
        totalFats > Double(mealType.targetCalories) * 0.3 / 9 // 30% калорий из жиров
    }
    
    var isOverCarbs: Bool {
        totalCarbs > Double(mealType.targetCalories) * 0.4 / 4 // 40% калорий из углеводов
    }
}

extension Meal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meal> {
        return NSFetchRequest<Meal>(entityName: "Meal")
    }
    
    // Получение приемов пищи за определенный день
    static func fetchMealsForDate(_ date: Date, context: NSManagedObjectContext) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request = Meal.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Ошибка при загрузке приемов пищи: \(error)")
            return []
        }
    }
    
    // Получение последних приемов пищи
    static func fetchRecentMeals(limit: Int = 5, context: NSManagedObjectContext) -> [Meal] {
        let request = Meal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Ошибка при загрузке последних приемов пищи: \(error)")
            return []
        }
    }
} 