import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var age: Int16
    @NSManaged public var birthday: Date?
    @NSManaged public var gender: String?
    @NSManaged public var height: Double
    @NSManaged public var weight: Double
    @NSManaged public var currentWeight: Double
    @NSManaged public var targetWeight: Double
    @NSManaged public var goalRawValue: String
    @NSManaged public var dailyCalorieTarget: Int32
    @NSManaged public var waterTarget: Int32
    @NSManaged public var isOnboardingCompleted: Bool
    @NSManaged public var lastSyncTimestamp: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var workouts: Set<Workout>?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        isOnboardingCompleted = false
        goalRawValue = Goal.maintenance.rawValue
    }
    
    var goal: Goal {
        get {
            Goal(rawValue: goalRawValue) ?? .maintenance
        }
        set {
            goalRawValue = newValue.rawValue
        }
    }
}

extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
} 