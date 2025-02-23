import CoreData

protocol CoreDataModel: NSManagedObject, Identifiable {
    static var entityName: String { get }
}

extension CoreDataModel {
    static var entityName: String {
        String(describing: self)
    }
    
    static func fetchRequest() -> NSFetchRequest<Self> {
        NSFetchRequest<Self>(entityName: entityName)
    }
} 