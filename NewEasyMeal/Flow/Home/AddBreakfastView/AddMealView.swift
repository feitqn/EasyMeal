// MARK: - AddBreakfastView
import SwiftUI

struct AddMealView: View {
    let foodName: String = "Acai Berry"
    let portion: String = "1 portion (100 g)"
    var food: FoodItem
    var onAddTap: Callback
    
    @State private var servingInput: String = ""
    @State private var showSuccess = false
    @State private var showError = false

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.title3).bold()
                Text(food.detail)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                NutritionCircle(label: "#Calorie", value: food.calories)
                NutritionCircle(label: "#Protein", value: food.nutrition.protein)
                NutritionCircle(label: "#Carbs", value: food.nutrition.carbs)
                NutritionCircle(label: "#Fats", value: food.nutrition.fats)
            }

            HStack {
                Text("Calorie")
                    .foregroundColor(.gray)
                Spacer()
                Text("\(food.calories) kcal")
                    .bold()
            }
            Divider()

            HStack {
                Text("Serving(g)")
                    .foregroundColor(.gray)
                Spacer()
                TextField("Enter", text: $servingInput)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
            }
            Divider()

            CustomButtonView(title: "Add") {
                onAddTap()
            }
            .frame(width: 300, height: 60)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .alert(isPresented: $showSuccess) {
            Alert(
                title: Text("Successfully Added!"),
                message: Text("Breakfast updated — keep going!"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Failed to Add Food!"),
                message: Text("Please try again later."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - NutritionCircle
struct NutritionCircle: View {
    let label: String
    let value: Int

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: CGFloat(value / 100))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 50, height: 50)
                Text("\(value)g")
                    .font(.urbanSemiBold(size: 15))
                    .lineLimit(1)
            }
            Text(label)
                .font(.caption2)
                .lineLimit(1)
        }
    }
}
// 
