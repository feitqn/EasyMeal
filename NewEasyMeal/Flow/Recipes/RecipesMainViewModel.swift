
import SwiftUI

class RecipesMainViewModel: ObservableObject {
    @Published var selectedCategory: String = "All"
    @Published var isFavoritesMode: Bool = false
    @Published var categories: [String] = ["All", "Breakfast", "Lunch", "Dinner", "Snack"]
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var showFilterSheet: Bool = false
    
    // Filter states
    @Published var selectedDateType: String = "All"
    @Published var selectedCookTime: String = "All"
    @Published var selectedDish: String = "All"
    @Published var selectedCookingMethod: String = "All"
    
    @Published var allRecipes: [RecipeMain] = []
    
    var dateTypes: [String] = ["All", "Breakfast", "Brunch", "Lunch", "Snack", "Dinner"]
    var cookTimes: [String] = ["All", "Under 10 min", "Under 20 min", "Under 30 min"]
    var suggestedDishes: [String] = ["All", "Vegetarian", "Beverage", "Gluten Free", "Sugar Free", "Low Fat"]
    var cookingMethods: [String] = ["All", "Grilled", "Baked", "Fried", "Steamed", "Raw (No Cook)"]
    
    var filteredRecipes: [RecipeMain] {
        allRecipes.filter { recipe in
            let matchesCategory = selectedCategory == "All" || recipe.category == selectedCategory
            let matchesFavorites = !isFavoritesMode || recipe.isFavorite
            let matchesSearch = searchText.isEmpty || recipe.title.lowercased().contains(searchText.lowercased())
            
            // Additional filters
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
            
            let matchesDish = selectedDish == "All" || recipe.tags.contains(selectedDish)
            let matchesCookingMethod = selectedCookingMethod == "All" || recipe.cookingMethod == selectedCookingMethod
            
            return matchesCategory && matchesFavorites && matchesSearch &&
                   matchesDateType && matchesCookTime && matchesDish && matchesCookingMethod
        }
    }
    
    var filteredRecipesByCategory: [String: [RecipeMain]] {
        return Dictionary(grouping: filteredRecipes, by: \.category)
    }
    
    var recommendations: [RecipeMain] {
        return Array(filteredRecipes.filter { $0.isFavorite }.prefix(4))
    }
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        allRecipes = [
            RecipeMain(title: "Shakshuka", imageName: "shakshuka", category: "Breakfast", cookTime: 25, isFavorite: true, tags: ["Vegetarian"], cookingMethod: "Baked"),
            RecipeMain(title: "Berry French Toast", imageName: "shakshuka", category: "Breakfast", cookTime: 15, isFavorite: false, tags: ["Sugar Free"], cookingMethod: "Fried"),
            RecipeMain(title: "Toast with Egg", imageName: "shakshuka", category: "Breakfast", cookTime: 8, isFavorite: true, tags: ["Low Fat"], cookingMethod: "Fried"),
            RecipeMain(title: "Egg Sandwich", imageName: "shakshuka", category: "Breakfast", cookTime: 5, isFavorite: false, tags: ["Low Fat"], cookingMethod: "Raw (No Cook)"),
            RecipeMain(title: "Tofu Noodles", imageName: "shakshuka", category: "Lunch", cookTime: 20, isFavorite: false, tags: ["Vegetarian"], cookingMethod: "Fried"),
            RecipeMain(title: "Beef Stirfry Noodles", imageName: "shakshuka", category: "Lunch", cookTime: 25, isFavorite: true, tags: [], cookingMethod: "Fried"),
            RecipeMain(title: "Broccoli Salad", imageName: "shakshuka", category: "Lunch", cookTime: 10, isFavorite: false, tags: ["Vegetarian", "Low Fat"], cookingMethod: "Raw (No Cook)"),
            RecipeMain(title: "Tomato Soup", imageName: "shakshuka", category: "Lunch", cookTime: 30, isFavorite: true, tags: ["Vegetarian", "Gluten Free"], cookingMethod: "Baked"),
            RecipeMain(title: "Spaghetti Bolognese", imageName: "shakshuka", category: "Dinner", cookTime: 35, isFavorite: true, tags: [], cookingMethod: "Baked"),
            RecipeMain(title: "Shrimp Lasagna", imageName: "shakshuka", category: "Dinner", cookTime: 45, isFavorite: false, tags: [], cookingMethod: "Baked"),
            RecipeMain(title: "Tartare with mushrooms", imageName: "shakshuka", category: "Snack", cookTime: 15, isFavorite: true, tags: ["Low Fat"], cookingMethod: "Raw (No Cook)"),
            RecipeMain(title: "Nachos", imageName: "shakshuka", category: "Snack", cookTime: 10, isFavorite: false, tags: ["Vegetarian"], cookingMethod: "Baked"),
            RecipeMain(title: "Spring Rolls", imageName: "shakshuka", category: "Snack", cookTime: 25, isFavorite: true, tags: [], cookingMethod: "Fried"),
            RecipeMain(title: "Cheese Balls", imageName: "shakshuka", category: "Snack", cookTime: 20, isFavorite: false, tags: ["Vegetarian"], cookingMethod: "Fried")
        ]
    }
    
    func resetFilters() {
        selectedDateType = "All"
        selectedCookTime = "All"
        selectedDish = "All"
        selectedCookingMethod = "All"
    }
}
