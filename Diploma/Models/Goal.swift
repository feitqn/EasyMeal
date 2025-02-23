import Foundation

enum Goal: String, CaseIterable, Codable {
    case maintenance = "Поддержание веса"
    case loss = "Похудение"
    case gain = "Набор веса"
    
    var weightLoss: Double {
        switch self {
        case .loss: return -0.5
        case .gain: return 0.5
        case .maintenance: return 0.0
        }
    }
    
    var weightGain: Double {
        switch self {
        case .loss: return -0.5
        case .gain: return 0.5
        case .maintenance: return 0.0
        }
    }
} 