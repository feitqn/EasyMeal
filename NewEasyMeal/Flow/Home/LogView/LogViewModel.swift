import SwiftUI

@MainActor
class LogMainViewModel: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: LogCategory = .recipes
    @Published var showCancelButton: Bool = false
    
    let mealType: MealType
    
    init(mealType: MealType) {
        self.mealType = mealType
    }
    
    var filteredItems: [FoodItem] {
        let categorizedItems = foodItems
        
        guard !searchText.isEmpty else { return categorizedItems }
        return categorizedItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchFoodItems() {
        Task {
            do {
                foodItems = try await APIHelper.shared.fetchRecipes()
                foodItems = selectedCategory == .favourites ? foodItems.filter { $0.isFavorite } : foodItems
                foodItems = foodItems.filter { $0.category == mealType.rawValue }
            } catch {
                print(error)
            }
        }
    }
}
