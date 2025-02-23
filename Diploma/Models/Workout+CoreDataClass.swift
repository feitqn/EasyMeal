import Foundation
import CoreData

@objc(CDWorkout)
public class CDWorkout: NSManagedObject, Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, workoutDescription, type, difficulty
        case duration, caloriesBurned, date, createdAt, updatedAt
        case exercises, user
    }
    
    required public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.managedObjectContext] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing managed object context"
            ))
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "CDWorkout", in: context) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing entity description"
            ))
        }
        
        super.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        workoutDescription = try container.decodeIfPresent(String.self, forKey: .workoutDescription)
        type = try container.decode(String.self, forKey: .type)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        duration = try container.decode(Int32.self, forKey: .duration)
        caloriesBurned = try container.decode(Int32.self, forKey: .caloriesBurned)
        date = try container.decode(Date.self, forKey: .date)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        if let exercisesData = try container.decodeIfPresent([CDExercise].self, forKey: .exercises) {
            exercises = Set(exercisesData)
        }
        
        if let userData = try container.decodeIfPresent(CDUser.self, forKey: .user) {
            user = userData
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(workoutDescription, forKey: .workoutDescription)
        try container.encode(type, forKey: .type)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(duration, forKey: .duration)
        try container.encode(caloriesBurned, forKey: .caloriesBurned)
        try container.encode(date, forKey: .date)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        if let exercisesSet = exercises {
            try container.encode(Array(exercisesSet), forKey: .exercises)
        }
        
        if let userObject = user {
            try container.encode(userObject, forKey: .user)
        }
    }
    
    @objc override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
} 