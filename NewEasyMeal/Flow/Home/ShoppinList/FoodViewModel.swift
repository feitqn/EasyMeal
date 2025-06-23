import Foundation
// MARK: - ViewModel

class FoodViewModel: ObservableObject {
    @Published var items: [FoodItem] = []
    @Published var itemsIDs: [String] = []
    
    @Published var checkedIngredients: [String: Set<String>] = [:]
    
    func fetchFoodItems() {
        Task {
            do {
                itemsIDs = try await APIHelper.shared.fetchShoppingListIDs()
                items = try await APIHelper.shared.fetchRecipes().filter { itemsIDs.contains($0.id) }
                print(items)
            } catch {
                print(error)
            }
        }
    }
    
    func removeItem(_ item: FoodItem) {
        items.removeAll { $0.id == item.id }
        checkedIngredients.removeValue(forKey: item.id)
        
        Task {
            do {
                try await APIHelper.shared.toggleShoppingList(for: item.id, toDelete: true)
                fetchFoodItems()
            } catch {
                print("Ошибка при обновлении избранного: \(error)")
            }
        }
        //        toggle(isIn: false, for: item)
    }
    
    func toggleIngredient(for itemId: String, ingredient: String) {
        if checkedIngredients[itemId] == nil {
            checkedIngredients[itemId] = Set<String>()
        }
        
        if checkedIngredients[itemId]!.contains(ingredient) {
            checkedIngredients[itemId]!.remove(ingredient)
        } else {
            checkedIngredients[itemId]!.insert(ingredient)
        }
    }
    
    func isIngredientChecked(itemId: String, ingredient: String) -> Bool {
        return checkedIngredients[itemId]?.contains(ingredient) ?? false
    }
}
