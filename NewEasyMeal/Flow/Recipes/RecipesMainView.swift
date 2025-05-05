
import SwiftUI

struct RecipesMainView: View {
    @ObservedObject var viewModel: RecipesMainViewModel
    @State private var selectedTab = 0
    
    var body: some View {
//        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isSearching {
                    searchView
                    Spacer()
                } else if viewModel.showFilterSheet {
                    filterView
                } else {
                    mainContentView
                }
            }
//            .navigationBarHidden(true)
//        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                header
                
                // Tab Switch
                tabSwitch
                
                // Category Tabs
                categoryTabs
                
                // Recommendations
                if !viewModel.recommendations.isEmpty {
                    recommendationsSection
                }
                
                // Recipes by category
                ForEach(viewModel.categories.filter { $0 != "All" }, id: \.self) { category in
                    if let recipes = viewModel.filteredRecipesByCategory[category], !recipes.isEmpty {
                        recipeSection(title: category, recipes: recipes)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Search View
    private var searchView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search header
            HStack {
                Button(action: {
                    viewModel.isSearching = false
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
                
                SearchBar(text: $viewModel.searchText)
                
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .opacity(viewModel.searchText.isEmpty ? 0 : 1)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Recent searches
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent searches")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(["Broccoli salad", "Toast", "Noodles"], id: \.self) { search in
                    Button(action: {
                        viewModel.searchText = search
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.gray)
                            Text(search)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Divider()
            
            // Search results
            if !viewModel.searchText.isEmpty {
                if viewModel.filteredRecipes.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("No recipes matched your search.")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.filteredRecipes) { recipe in
                                RecipeCard(recipe: recipe)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    // MARK: - Filter View
    private var filterView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Filter header
            HStack {
                Button(action: {
                    viewModel.showFilterSheet = false
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Filter")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear all") {
                    viewModel.resetFilters()
                }
                .foregroundColor(.green)
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date type filter
                    FilterSection(title: "Date type", options: viewModel.dateTypes, selectedOption: $viewModel.selectedDateType)
                    
                    // Cook time filter
                    FilterSection(title: "Cook time", options: viewModel.cookTimes, selectedOption: $viewModel.selectedCookTime)
                    
                    // Suggested dish filter
                    FilterSection(title: "Suggested dish", options: viewModel.suggestedDishes, selectedOption: $viewModel.selectedDish)
                    
                    // Cooking method filter
                    FilterSection(title: "Cooking Method", options: viewModel.cookingMethods, selectedOption: $viewModel.selectedCookingMethod)
                }
                .padding()
            }
            
            // Show Results button
            Button(action: {
                viewModel.showFilterSheet = false
            }) {
                Text("Show Results(\(viewModel.filteredRecipes.count))")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding()
            }
        }
    }
    
    // MARK: - UI Components
    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Hi, Normal")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Recipes")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.isSearching = true
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            Button(action: {
                viewModel.showFilterSheet = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding(.leading, 8)
            }
        }
    }
    
    private var tabSwitch: some View {
        HStack {
            Button(action: {
                viewModel.isFavoritesMode = false
            }) {
                Text("All Recipes")
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(viewModel.isFavoritesMode ? Color.gray.opacity(0.1) : Color.green.opacity(0.2))
                    .cornerRadius(20)
            }
            
            Button(action: {
                viewModel.isFavoritesMode = true
            }) {
                Text("Favourites")
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(viewModel.isFavoritesMode ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryButton(
                        icon: iconFor(category: category),
                        title: category,
                        isSelected: viewModel.selectedCategory == category
                    )
                    .onTapGesture {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommendations")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("View all")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recommendations) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.top)
    }
    
    private func recipeSection(title: String, recipes: [RecipeMain]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("View all")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // Helper to get icon for category
    private func iconFor(category: String) -> String {
        switch category {
        case "All":
            return "square.grid.2x2"
        case "Breakfast":
            return "sunrise"
        case "Lunch":
            return "fork.knife"
        case "Dinner":
            return "moon.stars"
        case "Snack":
            return "carrot"
        default:
            return "circle"
        }
    }
}

// MARK: - Supporting Views
struct CategoryButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .gray)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .green : .gray)
        }
    }
}

struct RecipeCard: View {
    let recipe: RecipeMain
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(recipe.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 120)
                    .cornerRadius(12)
                
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.yellow)
                        .padding(8)
                }
            }
            
            Text(recipe.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(recipe.cookTime) min")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 160)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FilterSection: View {
    let title: String
    let options: [String]
    @Binding var selectedOption: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedOption == option ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(20)
                            .onTapGesture {
                                selectedOption = option
                            }
                    }
                }
            }
        }
    }
}

struct RecipeDetailView: View {
    let recipe: RecipeMain
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe image
                Image(recipe.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe title
                    Text(recipe.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Recipe info
                    HStack {
                        Label("\(recipe.cookTime) min", systemImage: "clock")
                        
                        Spacer()
                        
                        Label(recipe.category, systemImage: "tag")
                        
                        Spacer()
                        
                        Label(recipe.cookingMethod, systemImage: "flame")
                    }
                    .foregroundColor(.gray)
                    
                    // Tags
                    if !recipe.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Ingredients title
                    Text("Ingredients")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    // Sample ingredients
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 2 eggs")
                        Text("• 200g flour")
                        Text("• 100ml milk")
                        Text("• 1 tbsp sugar")
                        Text("• 1 tsp salt")
                    }
                    
                    Divider()
                    
                    // Instructions title
                    Text("Instructions")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    // Sample instructions
                    VStack(alignment: .leading, spacing: 12) {
                        instructionStep(number: 1, text: "Mix all dry ingredients in a bowl")
                        instructionStep(number: 2, text: "Add eggs and milk, whisk until smooth")
                        instructionStep(number: 3, text: "Heat a pan and cook until golden")
                    }
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.left")
                .foregroundColor(.black)
        })
    }
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .fontWeight(.medium)
            }
            
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct ContentView: View {
    @StateObject var viewModel = RecipesMainViewModel()
    
    var body: some View {
        RecipesMainView(viewModel: viewModel)
    }
}


