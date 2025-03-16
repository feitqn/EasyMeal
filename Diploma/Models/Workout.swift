import Foundation
import CoreData

@objc(Workout)
public class Workout: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var workoutDescription: String?
    @NSManaged public var type: String
    @NSManaged public var difficulty: String
    @NSManaged public var duration: Int32
    @NSManaged public var caloriesBurned: Int32
    @NSManaged public var date: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var exercises: Set<Exercise>?
    @NSManaged public var user: User?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        updatedAt = Date()
        date = Date()
    }
}

extension Workout {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        return NSFetchRequest<Workout>(entityName: "Workout")
    }
} 