import Foundation

enum NetworkErrorReason: LocalizedError {
    case noConnection
    case timeout
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Нет подключения к интернету"
        case .timeout:
            return "Превышено время ожидания"
        case .serverError:
            return "Ошибка сервера"
        case .unknown:
            return "Неизвестная сетевая ошибка"
        }
    }
} 