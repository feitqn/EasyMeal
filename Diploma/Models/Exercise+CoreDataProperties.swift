import Foundation
import CoreData

extension CDExercise {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDExercise> {
        return NSFetchRequest<CDExercise>(entityName: "Exercise")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var exerciseDescription: String?
    @NSManaged public var muscleGroup: String
    @NSManaged public var type: String
    @NSManaged public var sets: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var weight: Double
    @NSManaged public var duration: Int32
    @NSManaged public var videoUrl: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var workouts: Set<CDWorkout>?
}

// MARK: Generated accessors for workouts
extension CDExercise {
    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: CDWorkout)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: CDWorkout)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSSet)
}

extension CDExercise: Identifiable {} 