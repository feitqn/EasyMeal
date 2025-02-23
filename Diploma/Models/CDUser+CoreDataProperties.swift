import Foundation
import CoreData

extension CDUser {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUser> {
        return NSFetchRequest<CDUser>(entityName: "CDUser")
    }

    @NSManaged public var id: String?
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var age: Int16
    @NSManaged public var weight: Double
    @NSManaged public var height: Double
    @NSManaged public var goalRawValue: String?
    @NSManaged public var dailyCalorieTarget: Int32
    @NSManaged public var waterTarget: Int32
    @NSManaged public var isOnboardingCompleted: Bool
    @NSManaged public var lastSyncTimestamp: Date?
    @NSManaged public var workouts: Set<CDWorkout>?
    @NSManaged public var gender: String?
    @NSManaged public var birthday: Date?
    @NSManaged public var targetWeight: Double
    @NSManaged public var currentWeight: Double
}

// MARK: Generated accessors for workouts
extension CDUser {
    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: CDWorkout)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: CDWorkout)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSSet)
}

extension CDUser {
    var goal: Goal {
        get {
            Goal(rawValue: goalRawValue ?? "") ?? .maintenance
        }
        set {
            goalRawValue = newValue.rawValue
        }
    }
} 