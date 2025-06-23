import SwiftUI

@MainActor
class LogMainViewModel: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: LogCategory = .recipes
    @Published var showCancelButton: Bool = false
    
    private let mealType: MealType
    
    
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
                let type = mealType.mapToRecipeType()
                foodItems = foodItems.filter { $0.category == type.rawValue }
            } catch {
                print(error)
            }
        }
    }
}

enum RecipesType: String {
    case breakFast = "Breakfast"
    case lunch = "Lunch"
    case snack = "Snacks"
    case dinner = "Dinner"
}

extension MealType {
    func mapToRecipeType() -> RecipesType {
        switch self {
        case .breakFast:
            return .breakFast
        case .lunch:
            return .lunch
        case .snack:
            return .snack
        case .dinner:
            return .dinner
        }
    }
}
