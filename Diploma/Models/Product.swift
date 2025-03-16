import Foundation
import CoreData

@objc(Product)
public class Product: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var calories: Int32
    @NSManaged public var protein: Double
    @NSManaged public var fats: Double
    @NSManaged public var carbs: Double
    @NSManaged public var portionSize: Double
    @NSManaged public var portionUnit: String
    @NSManaged public var meals: Set<Meal>?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID().uuidString
        portionUnit = "г"
        portionSize = 100
    }
    
    // Вычисляемые свойства для пищевой ценности на порцию
    var caloriesPerPortion: Double {
        Double(calories) * (portionSize / 100.0)
    }
    
    var proteinPerPortion: Double {
        protein * (portionSize / 100.0)
    }
    
    var fatsPerPortion: Double {
        fats * (portionSize / 100.0)
    }
    
    var carbsPerPortion: Double {
        carbs * (portionSize / 100.0)
    }
    
    // Метод для изменения размера порции
    func updatePortionSize(_ newSize: Double) {
        let ratio = newSize / portionSize
        portionSize = newSize
        calories = Int32(Double(calories) * ratio)
        protein *= ratio
        fats *= ratio
        carbs *= ratio
    }
    
    // Проверка корректности значений
    var isValid: Bool {
        // Проверяем основные параметры
        guard !name.isEmpty,
              calories >= 0,
              protein >= 0, fats >= 0, carbs >= 0,
              portionSize > 0 else {
            return false
        }
        
        // Проверяем сумму макронутриентов
        let totalGrams = protein + fats + carbs
        return totalGrams <= portionSize
    }
    
    // Форматированное отображение пищевой ценности
    var nutritionInfo: String {
        return """
        Калории: \(Int(caloriesPerPortion)) ккал
        Белки: \(String(format: "%.1f", proteinPerPortion))г
        Жиры: \(String(format: "%.1f", fatsPerPortion))г
        Углеводы: \(String(format: "%.1f", carbsPerPortion))г
        """
    }
}

extension Product {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }
    
    // Поиск продуктов по названию
    static func searchProducts(matching query: String, in context: NSManagedObjectContext) -> [Product] {
        let request = Product.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Ошибка при поиске продуктов: \(error)")
            return []
        }
    }
    
    // Получение часто используемых продуктов
    static func fetchFrequentlyUsedProducts(limit: Int = 10, in context: NSManagedObjectContext) -> [Product] {
        let request = Product.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Product.meals?.count, ascending: false)
        ]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Ошибка при загрузке частых продуктов: \(error)")
            return []
        }
    }
} 