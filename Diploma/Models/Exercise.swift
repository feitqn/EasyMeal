import Foundation
import CoreData

@objc(Exercise)
public class Exercise: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var exerciseDescription: String?
    @NSManaged public var muscleGroup: String
    @NSManaged public var type: String
    @NSManaged public var sets: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var duration: Int32
    @NSManaged public var weight: Double
    @NSManaged public var videoUrl: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var workouts: Set<Workout>?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        updatedAt = Date()
    }
}

extension Exercise {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }
} 