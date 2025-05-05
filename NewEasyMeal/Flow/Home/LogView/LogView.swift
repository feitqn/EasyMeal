import SwiftUI

enum LogCategory: String, CaseIterable, Identifiable {
    case products = "Products"
    case recipes = "Recipes"
    case favourites = "Favourites"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .products: return "leaf.fill"
        case .recipes: return "book.fill"
        case .favourites: return "bookmark.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .products: return Color.green
        case .recipes: return Color.orange
        case .favourites: return Color.yellow
        }
    }
    
    var iconBackgroundColor: Color {
        return Color.white
    }
}

// MARK: - Models

struct FoodItem: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let detail: String
    let nutrition: NutritionInfo
    
    // Adding this for filtering items based on category
    var category: LogCategory = .products
}

// MARK: - Components

struct CategoryButtonDemo: View {
    let category: LogCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(isSelected ? Colors.greenColor : category.iconBackgroundColor)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(category.iconColor)
            }
            
            Text(category.rawValue)
                .font(.system(size: 14))
                .foregroundColor(.black)
        }
        .onTapGesture(perform: action)
    }
}

struct FoodItemRow: View {
    let item: FoodItem
    let onAddTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 18, weight: .bold))
                
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("\(item.calories) Cal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(item.detail)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: onAddTap) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.indigo)
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Main View

struct LogView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: LogCategory = .products
    @State private var showCancelButton: Bool = false
    
    let onExitTap: Callback
    let onAddTap: ((FoodItem) -> ())?
    
    // Sample food items with some assigned to different categories
    private let foodItems: [FoodItem] = [
        .init(name: "Actimel (Danone)", calories: 59, detail: "1 bottle (100 g)", nutrition: NutritionInfo(protein: 10, carbs: 30, fats: 40)),
        .init(name: "Activia Strawberry (Danone)", calories: 73, detail: "1 package (115 g)", nutrition: NutritionInfo(protein: 30, carbs: 20, fats: 100)),
    ]
    
    var filteredItems: [FoodItem] {
        let categorizedItems = foodItems.filter { $0.category == selectedCategory }
        
        guard !searchText.isEmpty else { return categorizedItems }
        return categorizedItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 15)
                .padding(.bottom, 10)
            
            searchBar
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
            
            categorySelector
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
            
            itemList
                .padding(.horizontal, 20)
        }
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private var header: some View {
        HStack {
            Button(action: onExitTap) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            Text("Log Your Breakfast")
                .font(.system(size: 22, weight: .bold))
            
            Spacer()
            
            // Invisible spacer to balance the layout
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
    }
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 15)
                
                TextField("Search...", text: $searchText)
                    .font(.system(size: 16))
                    .padding(.vertical, 12)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 15)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 25) {
                ForEach(LogCategory.allCases) { category in
                    CategoryButtonDemo(
                        category: category,
                        isSelected: category == selectedCategory,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 5)
        }
    }
    
    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredItems) { item in
                    FoodItemRow(item: item) {
                        onAddTap?(item)
                    }
                }
                
                // Add some bottom padding for better scrolling
                Color.clear.frame(height: 20)
            }
        }
    }
}

// MARK: - Preview
struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(onExitTap: {}, onAddTap: { _ in})
    }
}
