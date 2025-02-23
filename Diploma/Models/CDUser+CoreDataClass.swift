import Foundation
import CoreData

@objc(CDUser)
public class CDUser: NSManagedObject, Codable {
    enum CodingKeys: String, CodingKey {
        case id, username, email, createdAt, age
        case weight, height, goal, dailyCalorieTarget
        case waterTarget, isOnboardingCompleted
        case lastSyncTimestamp, workouts
        case gender, birthday, targetWeight, currentWeight
    }
    
    required public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.managedObjectContext] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing managed object context"
            ))
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "CDUser", in: context) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing entity description"
            ))
        }
        
        super.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        age = try container.decode(Int16.self, forKey: .age)
        weight = try container.decode(Double.self, forKey: .weight)
        height = try container.decode(Double.self, forKey: .height)
        goalRawValue = try container.decode(String.self, forKey: .goal)
        dailyCalorieTarget = try container.decode(Int32.self, forKey: .dailyCalorieTarget)
        waterTarget = try container.decode(Int32.self, forKey: .waterTarget)
        isOnboardingCompleted = try container.decode(Bool.self, forKey: .isOnboardingCompleted)
        lastSyncTimestamp = try container.decodeIfPresent(Date.self, forKey: .lastSyncTimestamp)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        birthday = try container.decodeIfPresent(Date.self, forKey: .birthday)
        targetWeight = try container.decode(Double.self, forKey: .targetWeight)
        currentWeight = try container.decode(Double.self, forKey: .currentWeight)
        
        if let workoutsData = try container.decodeIfPresent([CDWorkout].self, forKey: .workouts) {
            workouts = Set(workoutsData)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(age, forKey: .age)
        try container.encode(weight, forKey: .weight)
        try container.encode(height, forKey: .height)
        try container.encode(goalRawValue, forKey: .goal)
        try container.encode(dailyCalorieTarget, forKey: .dailyCalorieTarget)
        try container.encode(waterTarget, forKey: .waterTarget)
        try container.encode(isOnboardingCompleted, forKey: .isOnboardingCompleted)
        try container.encodeIfPresent(lastSyncTimestamp, forKey: .lastSyncTimestamp)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(birthday, forKey: .birthday)
        try container.encode(targetWeight, forKey: .targetWeight)
        try container.encode(currentWeight, forKey: .currentWeight)
        
        if let workoutsSet = workouts {
            try container.encode(Array(workoutsSet), forKey: .workouts)
        }
    }
    
    @objc override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}