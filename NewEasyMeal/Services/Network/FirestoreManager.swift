import FirebaseFirestore
import FirebaseAuth

final class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()


    func fetchData<T: Codable>(fromCollection collection: String, documentId: String) async throws -> T {
        
        let documentSnapshot = try await db.collection(collection).document(documentId).getDocument()
        
        guard let data = documentSnapshot.data() else {
            throw NSError(domain: "FirestoreManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
        }

        let decoder = JSONDecoder()
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let model = try decoder.decode(T.self, from: jsonData)
        
        return model
    }

    func createTodayFoodDiary(userId: String, foodDiary: FoodDiary) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: Date())
        
        let documentRef = db.collection("users")
            .document(userId)
            .collection("FoodDiary")
            .document(todayKey)
        
        do {
            let data = try Firestore.Encoder().encode(foodDiary)

            documentRef.setData(data) { error in
                if let error = error {
                    print("❌ Ошибка при записи дневника: \(error.localizedDescription)")
                } else {
                    print("✅ FoodDiary на \(todayKey) успешно сохранён.")
                }
            }
        } catch {
            print("❌ Ошибка кодирования: \(error)")
        }
    }
}
