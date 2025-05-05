import SwiftUI

struct MealCard: View {
    let meal: Meal
    var onAdd: () -> Void
    
    var body: some View {
        HStack {
            mealImage(for: meal.name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                
                Text(meal.progressStr)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: geometry.size.width - 30, height: 6)
                            .foregroundColor(AppColors.secondary)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: geometry.size.width * meal.progress, height: 6)
                            .foregroundColor(mealColor(for: meal.name))
                    }
                }
                .frame(height: 5)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 35))
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func mealColor(for mealType: String) -> Color {
        switch mealType.lowercased() {
        case "breakfast": return AppColors.breakfastColor
        case "lunch": return AppColors.lunchColor
        case "snack": return AppColors.snackColor
        case "dinner": return AppColors.dinnerColor
        default: return AppColors.primary
        }
    }
    
    private func mealImage(for mealType: String) -> Image {
        switch mealType.lowercased() {
        case "breakfast": return Image("breakfast")
        case "lunch": return Image("lunch")
        case "snack": return Image("snack")
        case "dinner": return Image("dinner")
        default: return Image("dinner")
        }
    }
}
