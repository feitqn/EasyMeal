import SwiftUI
import CoreData

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let mealType: MealType
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var showAddProduct = false
    @State private var selectedProducts: Set<Product> = []
    @State private var showNutritionAlert = false
    @State private var nutritionAlertMessage = ""
    @State private var showDuplicateAlert = false
    @State private var duplicateProduct: Product?
    
    @FetchRequest private var products: FetchedResults<Product>
    @FetchRequest private var frequentProducts: FetchedResults<Product>
    
    init(mealType: MealType) {
        self.mealType = mealType
        
        // Основной запрос продуктов
        _products = FetchRequest(
            entity: Product.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
            predicate: nil
        )
        
        // Запрос часто используемых продуктов
        _frequentProducts = FetchRequest(
            entity: Product.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Product.meals?.count, ascending: false)
            ],
            fetchLimit: 5
        )
    }
    
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return selectedTab == 2 ? 
                Array(frequentProducts) :
                Array(products)
        }
        return products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var totalCalories: Int32 {
        selectedProducts.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Double {
        selectedProducts.reduce(0) { $0 + $1.protein }
    }
    
    private var totalFats: Double {
        selectedProducts.reduce(0) { $0 + $1.fats }
    }
    
    private var totalCarbs: Double {
        selectedProducts.reduce(0) { $0 + $1.carbs }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Поисковая строка
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Поиск продуктов...", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Табы
                HStack(spacing: 20) {
                    TabButton(
                        title: "Продукты",
                        icon: "leaf",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        title: "Рецепты",
                        icon: "book",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                    
                    TabButton(
                        title: "Частые",
                        icon: "star",
                        isSelected: selectedTab == 2
                    ) {
                        selectedTab = 2
                    }
                }
                .padding()
                
                // Рекомендуемые порции
                if !selectedProducts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(selectedProducts), id: \.id) { product in
                                RecommendedPortionCard(product: product) { newSize in
                                    updateProductPortion(product, newSize: newSize)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
                
                // Выбранные продукты
                if !selectedProducts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Выбранные продукты")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(selectedProducts), id: \.id) { product in
                                    SelectedProductChip(
                                        product: product,
                                        onRemove: { removeProduct(product) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Общая информация
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Всего калорий: \(totalCalories)")
                                    .foregroundColor(totalCalories > Int32(mealType.targetCalories) ? .red : .primary)
                                Text("Б: \(Int(totalProtein))г  Ж: \(Int(totalFats))г  У: \(Int(totalCarbs))г")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            
                            Button("Добавить") {
                                saveMeal()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(selectedProducts.isEmpty)
                        }
                        .padding()
                    }
                    .background(Color(.systemGray6))
                }
                
                // Список продуктов
                List {
                    ForEach(filteredProducts, id: \.id) { product in
                        ProductRow(
                            product: product,
                            isSelected: selectedProducts.contains(product)
                        ) {
                            toggleProduct(product)
                        }
                    }
                }
            }
            .navigationTitle("Добавить \(mealType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddProduct) {
                AddProductView()
            }
            .alert("Внимание", isPresented: $showNutritionAlert) {
                Button("Все равно добавить") {
                    saveMealForced()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text(nutritionAlertMessage)
            }
            .alert("Продукт уже добавлен", isPresented: $showDuplicateAlert) {
                Button("Изменить порцию") {
                    if let product = duplicateProduct {
                        updateProductPortion(product, newSize: product.portionSize * 2)
                    }
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                if let product = duplicateProduct {
                    Text("'\(product.name)' уже добавлен в прием пищи. Хотите увеличить порцию?")
                }
            }
        }
    }
    
    private func toggleProduct(_ product: Product) {
        if selectedProducts.contains(product) {
            removeProduct(product)
        } else {
            addProduct(product)
        }
    }
    
    private func addProduct(_ product: Product) {
        if selectedProducts.contains(product) {
            duplicateProduct = product
            showDuplicateAlert = true
            return
        }
        selectedProducts.insert(product)
    }
    
    private func removeProduct(_ product: Product) {
        selectedProducts.remove(product)
    }
    
    private func updateProductPortion(_ product: Product, newSize: Double) {
        if var updatedProduct = selectedProducts.first(where: { $0.id == product.id }) {
            selectedProducts.remove(updatedProduct)
            updatedProduct.updatePortionSize(newSize)
            selectedProducts.insert(updatedProduct)
        }
    }
    
    private func checkNutrition() -> Bool {
        var warnings: [String] = []
        
        if totalCalories > Int32(mealType.targetCalories) {
            warnings.append("Превышение калорий на \(totalCalories - Int32(mealType.targetCalories)) ккал")
        }
        
        let maxProtein = Double(mealType.targetCalories) * 0.3 / 4
        if totalProtein > maxProtein {
            warnings.append("Превышение белков на \(Int(totalProtein - maxProtein))г")
        }
        
        let maxFats = Double(mealType.targetCalories) * 0.3 / 9
        if totalFats > maxFats {
            warnings.append("Превышение жиров на \(Int(totalFats - maxFats))г")
        }
        
        let maxCarbs = Double(mealType.targetCalories) * 0.4 / 4
        if totalCarbs > maxCarbs {
            warnings.append("Превышение углеводов на \(Int(totalCarbs - maxCarbs))г")
        }
        
        if !warnings.isEmpty {
            nutritionAlertMessage = warnings.joined(separator: "\n")
            showNutritionAlert = true
            return false
        }
        
        return true
    }
    
    private func saveMeal() {
        if checkNutrition() {
            saveMealForced()
        }
    }
    
    private func saveMealForced() {
        let meal = Meal(context: viewContext)
        meal.id = UUID().uuidString
        meal.type = mealType.rawValue
        meal.date = Date()
        meal.products = selectedProducts
        meal.calories = totalCalories
        
        if let user = try? viewContext.fetch(User.fetchRequest()).first {
            meal.user = user
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Ошибка при сохранении приема пищи: \(error)")
        }
    }
}

struct RecommendedPortionCard: View {
    let product: Product
    let onPortionChange: (Double) -> Void
    
    private let recommendedPortions: [Double] = [0.5, 1.0, 1.5, 2.0]
    
    var body: some View {
        VStack(spacing: 4) {
            Text(product.name)
                .font(.caption)
                .lineLimit(1)
            
            HStack(spacing: 8) {
                ForEach(recommendedPortions, id: \.self) { portion in
                    Button {
                        onPortionChange(product.portionSize * portion)
                    } label: {
                        Text("\(Int(product.portionSize * portion))\(product.portionUnit)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SelectedProductChip: View {
    let product: Product
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(product.name)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProductRow: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    @State private var showDetails = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.name)
                        .font(.headline)
                    Text("\(Int(product.portionSize)) \(product.portionUnit)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(product.calories) ккал")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 8) {
                        NutrientLabel(value: product.protein, unit: "Б")
                        NutrientLabel(value: product.fats, unit: "Ж")
                        NutrientLabel(value: product.carbs, unit: "У")
                    }
                }
                
                Button {
                    showDetails = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showDetails) {
            NavigationView {
                ProductDetailsView(product: product)
            }
        }
    }
}

struct NutrientLabel: View {
    let value: Double
    let unit: String
    
    var body: some View {
        Text("\(Int(value))\(unit)")
            .font(.caption)
            .foregroundColor(.gray)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .green : .gray)
        }
    }
}

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name = ""
    @State private var calories: Int32 = 0
    @State private var protein: Double = 0
    @State private var fats: Double = 0
    @State private var carbs: Double = 0
    @State private var portionSize: Double = 100
    @State private var portionUnit = "г"
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showNutritionCalculator = false
    
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
                    
                    Button("Рассчитать калории") {
                        showNutritionCalculator = true
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
            .navigationTitle("Новый продукт")
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
            .sheet(isPresented: $showNutritionCalculator) {
                NutritionCalculatorView(
                    protein: $protein,
                    fats: $fats,
                    carbs: $carbs,
                    calories: $calories
                )
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
        
        let product = Product(context: viewContext)
        product.id = UUID().uuidString
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

struct NutritionCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var protein: Double
    @Binding var fats: Double
    @Binding var carbs: Double
    @Binding var calories: Int32
    
    var calculatedCalories: Int32 {
        Int32(protein * 4 + fats * 9 + carbs * 4)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Макронутриенты")) {
                    HStack {
                        Text("Белки")
                        Spacer()
                        TextField("0", value: $protein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("г")
                    }
                    
                    HStack {
                        Text("Жиры")
                        Spacer()
                        TextField("0", value: $fats, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("г")
                    }
                    
                    HStack {
                        Text("Углеводы")
                        Spacer()
                        TextField("0", value: $carbs, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("г")
                    }
                }
                
                Section(header: Text("Расчет калорий")) {
                    HStack {
                        Text("Калории")
                        Spacer()
                        Text("\(calculatedCalories) ккал")
                            .foregroundColor(.orange)
                    }
                    
                    Button("Применить расчет") {
                        calories = calculatedCalories
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("Информация")) {
                    Text("1г белков = 4 ккал")
                    Text("1г жиров = 9 ккал")
                    Text("1г углеводов = 4 ккал")
                }
            }
            .navigationTitle("Калькулятор калорий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
} 