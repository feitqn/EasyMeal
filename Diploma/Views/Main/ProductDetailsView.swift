import SwiftUI

struct ProductDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let product: Product
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var portionSize: Double
    @State private var isEditing = false
    
    init(product: Product) {
        self.product = product
        _portionSize = State(initialValue: product.portionSize)
    }
    
    var body: some View {
        List {
            Section(header: Text("Основная информация")) {
                HStack {
                    Text("Название")
                    Spacer()
                    Text(product.name)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Размер порции")
                    Spacer()
                    if isEditing {
                        TextField("Размер порции", value: $portionSize, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(product.portionUnit)
                    } else {
                        Text("\(Int(product.portionSize)) \(product.portionUnit)")
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    isEditing.toggle()
                }
                
                if isEditing {
                    Button("Применить") {
                        product.updatePortionSize(portionSize)
                        try? viewContext.save()
                        isEditing = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.green)
                }
            }
            
            Section(header: Text("Пищевая ценность")) {
                NutritionRow(title: "Калории", value: Int(product.caloriesPerPortion), unit: "ккал")
                NutritionRow(title: "Белки", value: product.proteinPerPortion, unit: "г")
                NutritionRow(title: "Жиры", value: product.fatsPerPortion, unit: "г")
                NutritionRow(title: "Углеводы", value: product.carbsPerPortion, unit: "г")
            }
            
            if let meals = product.meals, !meals.isEmpty {
                Section(header: Text("Использование в приемах пищи")) {
                    ForEach(Array(meals), id: \.id) { meal in
                        HStack {
                            Text(meal.mealType.rawValue)
                            Spacer()
                            Text(meal.date, style: .date)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Удалить продукт")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Детали продукта")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Изменить")
                }
            }
        }
        .alert("Удалить продукт?", isPresented: $showDeleteAlert) {
            Button("Удалить", role: .destructive) {
                deleteProduct()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Это действие нельзя отменить")
        }
        .sheet(isPresented: $showEditSheet) {
            EditProductView(product: product)
        }
    }
    
    private func deleteProduct() {
        viewContext.delete(product)
        try? viewContext.save()
        dismiss()
    }
}

struct NutritionRow: View {
    let title: String
    let value: Double
    let unit: String
    
    init(title: String, value: Double, unit: String) {
        self.title = title
        self.value = value
        self.unit = unit
    }
    
    init(title: String, value: Int, unit: String) {
        self.title = title
        self.value = Double(value)
        self.unit = unit
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(String(format: "%.1f", value)) \(unit)")
                .foregroundColor(.gray)
        }
    }
}

struct EditProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let product: Product
    @State private var name: String
    @State private var calories: Int32
    @State private var protein: Double
    @State private var fats: Double
    @State private var carbs: Double
    @State private var portionSize: Double
    @State private var portionUnit: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(product: Product) {
        self.product = product
        _name = State(initialValue: product.name)
        _calories = State(initialValue: product.calories)
        _protein = State(initialValue: product.protein)
        _fats = State(initialValue: product.fats)
        _carbs = State(initialValue: product.carbs)
        _portionSize = State(initialValue: product.portionSize)
        _portionUnit = State(initialValue: product.portionUnit)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название", text: $name)
                    
                    HStack {
                        Text("Калории")
                        Spacer()
                        TextField("0", value: $calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Пищевая ценность (на 100г)")) {
                    HStack {
                        Text("Белки")
                        Spacer()
                        TextField("0", value: $protein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Жиры")
                        Spacer()
                        TextField("0", value: $fats, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Углеводы")
                        Spacer()
                        TextField("0", value: $carbs, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Размер порции")) {
                    HStack {
                        Text("Количество")
                        Spacer()
                        TextField("100", value: $portionSize, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Единица измерения", selection: $portionUnit) {
                        Text("г").tag("г")
                        Text("мл").tag("мл")
                        Text("шт").tag("шт")
                    }
                }
            }
            .navigationTitle("Изменить продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveProduct()
                    }
                    .disabled(!isValidForm)
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValidForm: Bool {
        !name.isEmpty && calories > 0 && protein >= 0 && fats >= 0 && carbs >= 0 && portionSize > 0
    }
    
    private func validateNutrients() -> Bool {
        let totalGrams = protein + fats + carbs
        if totalGrams > portionSize {
            errorMessage = "Сумма белков, жиров и углеводов не может превышать размер порции"
            showError = true
            return false
        }
        
        let calculatedCalories = protein * 4 + fats * 9 + carbs * 4
        let tolerance = 10.0 // допустимая погрешность в калориях
        if abs(calculatedCalories - Double(calories)) > tolerance {
            errorMessage = "Калорийность не соответствует содержанию БЖУ"
            showError = true
            return false
        }
        
        return true
    }
    
    private func saveProduct() {
        guard validateNutrients() else { return }
        
        product.name = name
        product.calories = calories
        product.protein = protein
        product.fats = fats
        product.carbs = carbs
        product.portionSize = portionSize
        product.portionUnit = portionUnit
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Ошибка при сохранении продукта: \(error.localizedDescription)"
            showError = true
        }
    }
} 