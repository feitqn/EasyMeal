import SwiftUI
import Kingfisher

// MARK: - Shopping List View
struct ShoppingListView: View {
    @StateObject var viewModel: FoodViewModel
    @State private var expandedItems: Set<String> = []
    var onTapBackButton: (() -> ())
    
    var body: some View {
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    HStack {
                        Button(action: {
                            onTapBackButton()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("Shopping List")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Invisible button for symmetry
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.clear)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.items, id: \.id) { item in
                            ShoppingListItemView(
                                item: item,
                                isExpanded: expandedItems.contains(item.id),
                                onToggleExpansion: {
                                    if expandedItems.contains(item.id) {
                                        expandedItems.remove(item.id)
                                    } else {
                                        expandedItems.insert(item.id)
                                    }
                                },
                                onRemoveItem: {
                                    viewModel.removeItem(item)
                                },
                                onToggleIngredient: { ingredient in
                                    viewModel.toggleIngredient(for: item.id, ingredient: ingredient)
                                },
                                isIngredientChecked: { ingredient in
                                    viewModel.isIngredientChecked(itemId: item.id, ingredient: ingredient)
                                }
                            )
                        }
                    }
                    .padding(.top, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .background(Color.white)
    }
}

// MARK: - Shopping List Item View
struct ShoppingListItemView: View {
    let item: FoodItem
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onRemoveItem: () -> Void
    let onToggleIngredient: (String) -> Void
    let isIngredientChecked: (String) -> Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Main item row
            HStack(spacing: 12) {
                // Food image
                KFImage(URL(string: item.imageName))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .cornerRadius(10)
                    .clipped()
                
                // Item info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text("\(item.ingredients?.count ?? 0) products")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Delete button
                Button(action: onRemoveItem) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .onTapGesture {
                onToggleExpansion()
            }
            
            // Ingredients list (expandable)
            if isExpanded, let ingredients = item.ingredients {
                VStack(spacing: 0) {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                        HStack(spacing: 12) {
                            Button(action: {
                                onToggleIngredient(ingredient)
                            }) {
                                Image(systemName: isIngredientChecked(ingredient) ? "checkmark.square.fill" : "checkmark.square")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.orange)
                            }
                            
                            Text(ingredient)
                                .font(.system(size: 16))
                                .foregroundColor(isIngredientChecked(ingredient) ? .gray : .black)
                                .strikethrough(isIngredientChecked(ingredient))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        
                        if index < ingredients.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            
            // Separator between items
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .frame(height: 8)
        }
    }
}
//
//// MARK: - Preview
//struct ShoppingListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ShoppingListView()
//    }
//}
