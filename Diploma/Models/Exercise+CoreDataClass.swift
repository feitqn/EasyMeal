import Foundation
import CoreData

@objc(CDExercise)
public class CDExercise: NSManagedObject, Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, exerciseDescription, type, muscleGroup
        case duration, sets, reps, weight, videoUrl
        case createdAt, updatedAt, workouts
    }
    
    required public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.managedObjectContext] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing managed object context"
            ))
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Exercise", in: context) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing entity description"
            ))
        }
        
        super.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        exerciseDescription = try container.decodeIfPresent(String.self, forKey: .exerciseDescription)
        type = try container.decode(String.self, forKey: .type)
        muscleGroup = try container.decode(String.self, forKey: .muscleGroup)
        duration = try container.decode(Int32.self, forKey: .duration)
        sets = try container.decode(Int16.self, forKey: .sets)
        reps = try container.decode(Int16.self, forKey: .reps)
        weight = try container.decode(Double.self, forKey: .weight)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        if let workoutsData = try container.decodeIfPresent([CDWorkout].self, forKey: .workouts) {
            workouts = Set(workoutsData)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(exerciseDescription, forKey: .exerciseDescription)
        try container.encode(type, forKey: .type)
        try container.encode(muscleGroup, forKey: .muscleGroup)
        try container.encode(duration, forKey: .duration)
        try container.encode(sets, forKey: .sets)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
        try container.encodeIfPresent(videoUrl, forKey: .videoUrl)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        if let workoutsSet = workouts {
            try container.encode(Array(workoutsSet), forKey: .workouts)
        }
    }
    
    @objc override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
} 