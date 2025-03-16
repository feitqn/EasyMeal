import SwiftUI
import CoreData

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Изображение рецепта
                AsyncImage(url: URL(string: recipe.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Основная информация
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            Label("\(recipe.cookingTime) мин", systemImage: "clock")
                            Label(recipe.difficulty, systemImage: "chart.bar")
                            Label("\(recipe.calories) ккал", systemImage: "flame")
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Пищевая ценность
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пищевая ценность")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            NutrientView(name: "Белки", value: recipe.protein)
                            NutrientView(name: "Жиры", value: recipe.fats)
                            NutrientView(name: "Углеводы", value: recipe.carbs)
                        }
                    }
                    
                    // Ингредиенты
                    if let ingredients = recipe.ingredients {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ингредиенты")
                                .font(.headline)
                            
                            ForEach(ingredients, id: \.self) { ingredient in
                                Text("• \(ingredient)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Шаги приготовления
                    if let steps = recipe.steps {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Приготовление")
                                .font(.headline)
                            
                            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .fontWeight(.bold)
                                    Text(step)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NutrientView: View {
    let name: String
    let value: Double
    
    var body: some View {
        VStack {
            Text("\(Int(value))г")
                .font(.headline)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 