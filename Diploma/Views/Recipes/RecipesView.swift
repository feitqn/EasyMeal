import SwiftUI
import CoreData

struct RecipesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.createdAt, ascending: false)],
        animation: .default
    ) private var recipes: FetchedResults<Recipe>
    
    @State private var selectedCategory: RecipeCategory?
    @State private var searchText = ""
    
    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            let matchesSearch = searchText.isEmpty || 
                recipe.name.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || 
                recipe.categoryRawValue == selectedCategory?.rawValue
                
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Категории
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(
                            title: "Все",
                            icon: "list.bullet",
                            isSelected: selectedCategory == nil,
                            color: .gray
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(RecipeCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category,
                                color: Color(category.color)
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Список рецептов
                List {
                    ForEach(filteredRecipes, id: \.id) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeRowView(recipe: recipe)
                        }
                    }
                }
            }
            .navigationTitle("Рецепты")
            .searchable(text: $searchText, prompt: "Поиск рецептов")
        }
    }
}

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: recipe.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                
                HStack {
                    Label("\(recipe.cookingTime) мин", systemImage: "clock")
                    Spacer()
                    Label("\(recipe.calories) ккал", systemImage: "flame")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
} 