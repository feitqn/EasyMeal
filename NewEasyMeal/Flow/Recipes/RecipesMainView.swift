
import SwiftUI
import Kingfisher

struct RecipesMainView: View {
    @ObservedObject var viewModel: RecipesMainViewModel
    @State private var selectedTab = 0
    @State private var showAlert = false
    @State private var alertType: FoodActionResultType = .success
    var onTapAdded: Callback
    var onTapShoppingList: Callback
    
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
                        .padding(.top, 1)
                        .overlay(
                            Group {
                                if showAlert {
                                    FoodActionAlertSwiftUIView(type: alertType)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    showAlert = false
                                                }
                                            }
                                        }
                                }
                            }
                        )
                        .animation(.easeInOut, value: showAlert)
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
//                if !viewModel.recommendations.isEmpty {
//                    recommendationsSection
//                }
                
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
            
            Button(action: {
                onTapShoppingList()
            }) {
                Image("shoppingList")
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
                
//                Text("View all")
//                    .font(.subheadline)
//                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recommendations) { recipe in
                        let view = RecipeDetailView(
                            onLikeButtonTapped: {
                                viewModel.toggleFavorite(for: recipe.id)
                            },
                            addToShoppingList: {
                                viewModel.addItem(recipe) {
                                    alertType = .success
                                    showAlert = true
                                }
                            },
                            showAlert: $showAlert,
                            alertType: $alertType,
                            recipe: recipe
                        )
                        NavigationLink(destination: view) {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.top)
    }
    
    private func recipeSection(title: String, recipes: [FoodItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
//                Text("View all")
//                    .font(.subheadline)
//                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recipes) { recipe in
                        let view = RecipeDetailView(
                            onLikeButtonTapped: {
                                viewModel.toggleFavorite(for: recipe.id)
                            },
                            addToShoppingList: {
                                viewModel.addItem(recipe) {
                                    alertType = .success
                                    showAlert = true
                                }
                            },
                            showAlert: $showAlert,
                            alertType: $alertType,
                            recipe: recipe
                        )
                        NavigationLink(destination: view) {
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
    let recipe: FoodItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                KFImage(URL(string: recipe.imageName))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 120)
                    .cornerRadius(12)
                    .clipped()
                
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.yellow)
                        .padding(8)
                }
            }
            
            Text(recipe.name)
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
    var onLikeButtonTapped: (() -> ())
    var addToShoppingList: (() -> ())
    
    @Binding var showAlert: Bool
    @Binding var alertType: FoodActionResultType
    
    @Environment(\.dismiss) var dismiss
    var recipe: FoodItem
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Group {
            let instructions = recipe.instructions ?? []
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack {
                        KFImage(URL(string: recipe.imageName))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: 250)
                            .clipped()

                        VStack {
                            HStack {
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .padding()
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: Color.gray.opacity(0.2), radius: 2)
                                }
                                Spacer()
                                Button(action: {
                                    onLikeButtonTapped()
                                }) {
                                    Image(systemName: "heart")
                                        .foregroundColor(.yellow)
                                        .symbolVariant(recipe.isFavorite ? .fill : .none)
                                        .padding()
                                        .shadow(color: Color.gray.opacity(0.2), radius: 2)
                                }
                            }.padding(.top, 16)
                            
                            Spacer()
                        }.padding(.leading, 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Recipe title
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Recipe info
                        HStack {
                            Label("\(recipe.cookTime) min", systemImage: "clock")
                            
                            Spacer()
                            
                            Label(recipe.category, systemImage: "tag")
                            
                            Spacer()
                            
                            Label(recipe.cookingMethod ?? "", systemImage: "flame")
                        }
                        .foregroundColor(.gray)
                        
                        HStack(spacing: 12) {
                            Spacer()
                            NutritionCircle(label: "#Calorie", value: recipe.calories)
                            NutritionCircle(label: "#Protein", value: recipe.nutrition.protein)
                            NutritionCircle(label: "#Carbs", value: recipe.nutrition.carbs)
                            NutritionCircle(label: "#Fats", value: recipe.nutrition.fats)
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Ingredients title
                        Text("Ingredients")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        // Sample ingredients
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.ingredients ?? [], id: \.self) { ingredient in
                                Text("• \(ingredient)")
                            }
                        }
                        
                        Divider()
                        
                        // Instructions title
                        Text("Instructions")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        // Sample instructions
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                                instructionStep(number: index + 1, text: step)
                            }
                        }
                    }
                    .padding()
                    
                    HStack {
                        Spacer()
                        
                        CustomButtonView(title: "Add to shopping list") {
                            addToShoppingList()
                        }
                        .frame(width: 300, height: 60)
                        .padding(.top, 42)
                        .padding(.bottom, 16)
                        
                        Spacer()
                    }
                }
            }
            .overlay(
                Group {
                    if showAlert {
                        FoodActionAlertSwiftUIView(type: alertType)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showAlert = false
                                    }
                                }
                            }
                    }
                }
            )
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.black)
            })
        }
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

