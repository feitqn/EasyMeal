import FirebaseStorage
import UIKit

class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage().reference()
    
    func uploadImage(_ image: UIImage, path: String) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidData
        }
        
        let ref = storage.child(path)
        _ = try await ref.putDataAsync(data)
        return try await ref.downloadURL()
    }
    
    func downloadImage(from path: String) async throws -> UIImage {
        let ref = storage.child(path)
        let data = try await ref.data(maxSize: 5 * 1024 * 1024)
        guard let image = UIImage(data: data) else {
            throw StorageError.invalidData
        }
        return image
    }
} 