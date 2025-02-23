import Foundation
import CoreData

extension CDWorkout {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkout> {
        return NSFetchRequest<CDWorkout>(entityName: "CDWorkout")
    }

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
    @NSManaged public var exercises: Set<CDExercise>?
    @NSManaged public var user: CDUser?
}

// MARK: Generated accessors for exercises
extension CDWorkout {
    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: CDExercise)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: CDExercise)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)
}

extension CDWorkout: Identifiable {} 