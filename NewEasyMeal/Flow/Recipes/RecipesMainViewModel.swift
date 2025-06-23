
import SwiftUI

@MainActor
class RecipesMainViewModel: ObservableObject {
    @Published var selectedCategory: String = "All" {
        didSet { applyFilters() }
    }
    @Published var isFavoritesMode: Bool = false {
        didSet { applyFilters() }
    }
    @Published var categories: [String] = ["All", "Breakfast", "Lunch", "Dinner", "Snacks"]
    @Published var searchText: String = "" {
        didSet { applyFilters() }
    }
    @Published var isSearching: Bool = false
    @Published var showFilterSheet: Bool = false
    
    // Filter states
    @Published var selectedDateType: String = "All" {
        didSet { applyFilters() }
    }
    @Published var selectedCookTime: String = "All" {
        didSet { applyFilters() }
    }
    @Published var selectedDish: String = "All" {
        didSet { applyFilters() }
    }
    @Published var selectedCookingMethod: String = "All" {
        didSet { applyFilters() }
    }
    @Published var allRecipes: [FoodItem] = []
    
    var dateTypes: [String] = ["All", "Breakfast", "Brunch", "Lunch", "Snacks", "Dinner"]
    var cookTimes: [String] = ["All", "Under 10 min", "Under 20 min", "Under 30 min"]
    var suggestedDishes: [String] = ["All", "Vegetarian", "Beverage", "Gluten Free", "Sugar Free", "Low Fat"]
    var cookingMethods: [String] = ["All", "Grilled", "Baked", "Fried", "Steamed", "Raw (No Cook)"]
    
    @Published var filteredRecipes: [FoodItem] = []
    
    @Published var filteredRecipesByCategory: [String: [FoodItem]] = [:]
    
    @Published var recommendations: [FoodItem] = []
    
    @Published var favoriteRecipeIDs: Set<String> = []

    func toggleFavorite(for id: String) {
        var toLike: Bool = true
        if favoriteRecipeIDs.contains(id) {
            favoriteRecipeIDs.remove(id)
            toLike = false
        } else {
            favoriteRecipeIDs.insert(id)
            toLike = true
        }

        // ✅ Обновляем isFavorite в allRecipes
        if let index = allRecipes.firstIndex(where: { $0.id == id }) {
            allRecipes[index].isFavorite = toLike
        }
        
        if let index = filteredRecipes.firstIndex(where: { $0.id == id }) {
            filteredRecipes[index].isFavorite = toLike
        }
        
        applyFilters()

        Task {
            do {
                try await APIHelper.shared.toggleFavorite(for: id, isFavorite: toLike)
//                loadMockData()
            } catch {
                print("Ошибка при обновлении избранного: \(error)")
            }
        }
    }
    
    func addItem(_ item: FoodItem, completion: @escaping Callback) {
        Task {
            do {
                try await APIHelper.shared.toggleShoppingList(for: item.id)
                completion()
            } catch {
                print("Ошибка при обновлении избранного: \(error)")
            }
        }
    }

    func loadMockData() {
        Task {
            do {
                let recipes = try await APIHelper.shared.fetchRecipes()
                allRecipes = recipes
                favoriteRecipeIDs = Set(recipes.filter { $0.isFavorite }.map { $0.id })
                applyFilters()
            } catch {
                print(error)
            }
        }
    }
    
    func applyFilters() {
        filteredRecipes = allRecipes.filter { recipe in
            let matchesCategory = selectedCategory == "All" || recipe.category == selectedCategory
            let matchesFavorites = !isFavoritesMode || recipe.isFavorite
            let matchesSearch = searchText.isEmpty || recipe.name.lowercased().contains(searchText.lowercased())
            let matchesDateType = selectedDateType == "All" || recipe.category == selectedDateType

            let matchesCookTime: Bool
            switch selectedCookTime {
            case "Under 10 min":
                matchesCookTime = recipe.cookTime < 10
            case "Under 20 min":
                matchesCookTime = recipe.cookTime < 20
            case "Under 30 min":
                matchesCookTime = recipe.cookTime < 30
            default:
                matchesCookTime = true
            }

            let matchesDish = true // или допиши как надо
            let matchesCookingMethod = selectedCookingMethod == "All" || recipe.cookingMethod == selectedCookingMethod

            return matchesCategory && matchesFavorites && matchesSearch &&
                   matchesDateType && matchesCookTime && matchesDish && matchesCookingMethod
        }

        filteredRecipesByCategory = Dictionary(grouping: filteredRecipes, by: \.category)
        recommendations = Array(filteredRecipes.filter { $0.isFavorite }.prefix(4))
    }

    func resetFilters() {
        selectedDateType = "All"
        selectedCookTime = "All"
        selectedDish = "All"
        selectedCookingMethod = "All"
    }
}
