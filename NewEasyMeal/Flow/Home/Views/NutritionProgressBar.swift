import SwiftUI

struct NutritionProgressBar: View {
    let info: Nutrition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(info.name)
                .font(Font.urbanSemiBold(size: 16))
                .foregroundColor(.black)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: geometry.size.width, height: 10)
                        .foregroundColor(AppColors.secondary)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: geometry.size.width * info.progress, height: 10)
                        .foregroundColor(nutritionColor(for: info.name))
                }
            }
            .frame(height: 10)
            
            Text(info.remainingText)
                .skeleton(with: info.remainingText.isEmpty, size: CGSize(width: 200, height: 30))
                .font(.urban(size: 13))
                .foregroundColor(.black)
        }
    }
    
    private func nutritionColor(for type: String) -> Color {
        switch type.lowercased() {
        case "carbs": return AppColors.breakfastColor
        case "protein": return AppColors.lunchColor
        case "fat": return AppColors.snackColor
        default: return AppColors.dinnerColor
        }
    }
}

