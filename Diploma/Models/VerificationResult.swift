import Foundation

enum VerificationResult {
    case success(String)
    case failure(Error)
    
    var userId: String? {
        switch self {
        case .success(let id):
            return id
        case .failure:
            return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
} 