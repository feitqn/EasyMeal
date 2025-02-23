import SwiftUI

struct TrackingView: View {
    @State private var selectedMeal: MealType = .breakfast
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Прием пищи", selection: $selectedMeal) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Text(meal.rawValue).tag(meal)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Здесь будет форма добавления продукта
                AddFoodForm()
                
                Spacer()
            }
            .navigationTitle("Добавить прием пищи")
        }
    }
}

enum MealType: String, CaseIterable {
    case breakfast = "Завтрак"
    case lunch = "Обед"
    case dinner = "Ужин"
    case snack = "Перекус"
}

struct AddFoodForm: View {
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fats = ""
    @State private var carbs = ""
    
    var body: some View {
        Form {
            Section(header: Text("Информация о продукте")) {
                TextField("Название продукта", text: $foodName)
                TextField("Калории", text: $calories)
                    .keyboardType(.numberPad)
                TextField("Белки (г)", text: $protein)
                    .keyboardType(.decimalPad)
                TextField("Жиры (г)", text: $fats)
                    .keyboardType(.decimalPad)
                TextField("Углеводы (г)", text: $carbs)
                    .keyboardType(.decimalPad)
            }
            
            Button("Добавить") {
                // Здесь будет логика сохранения
            }
        }
    }
} 