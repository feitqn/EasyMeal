import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Meal.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@ AND date < %@", 
            Calendar.current.startOfDay(for: Date()) as CVarArg,
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) as CVarArg)
    ) private var meals: FetchedResults<Meal>
    
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: []
    ) private var users: FetchedResults<User>
    
    @State private var showAddMeal = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingMealDetails = false
    @State private var selectedMeal: Meal?
    
    @State private var showDailyStats = false
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    
    private var user: User? {
        users.first
    }
    
    private var totalCaloriesEaten: Int {
        meals.reduce(0) { $0 + Int($1.calories) }
    }
    
    private var totalCaloriesBurned: Int {
        // В будущем будем получать из тренировок
        user?.workouts?.reduce(0) { $0 + Int($1.caloriesBurned) } ?? 0
    }
    
    private var remainingCalories: Int {
        Int(user?.dailyCalorieTarget ?? 2176) - totalCaloriesEaten + totalCaloriesBurned
    }
    
    private var totalProtein: Double {
        meals.reduce(0) { $0 + $1.totalProtein }
    }
    
    private var totalFats: Double {
        meals.reduce(0) { $0 + $1.totalFats }
    }
    
    private var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.totalCarbs }
    }
    
    private var mealsGroupedByType: [MealType: [Meal]] {
        Dictionary(grouping: meals) { meal in
            meal.mealType
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Карточка с дневной статистикой калорий
                    Button {
                        showDailyStats = true
                    } label: {
                        DailyCalorieCard(
                            caloriesEaten: totalCaloriesEaten,
                            caloriesBurned: totalCaloriesBurned,
                            remainingCalories: remainingCalories,
                            dailyTarget: Int(user?.dailyCalorieTarget ?? 2176),
                            protein: totalProtein,
                            fats: totalFats,
                            carbs: totalCarbs
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Секция приемов пищи
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Приемы пищи")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                showDatePicker = true
                            } label: {
                                HStack {
                                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                    Image(systemName: "calendar")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            let meals = mealsGroupedByType[mealType] ?? []
                            let totalCalories = meals.reduce(0) { $0 + Int($1.calories) }
                            
                            MealRow(
                                mealType: mealType,
                                calories: Int32(totalCalories),
                                targetCalories: Int32(mealType.targetCalories),
                                meals: meals
                            ) {
                                selectedMealType = mealType
                                showAddMeal = true
                            }
                            .onTapGesture {
                                if let meal = meals.first {
                                    selectedMeal = meal
                                    showingMealDetails = true
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Дневная сводка")
            .sheet(isPresented: $showAddMeal) {
                AddMealView(mealType: selectedMealType)
            }
            .sheet(isPresented: $showingMealDetails) {
                if let meal = selectedMeal {
                    MealDetailsView(meal: meal)
                }
            }
            .sheet(isPresented: $showDailyStats) {
                NavigationView {
                    DailyStatsView(date: selectedDate)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    DatePickerView(selectedDate: $selectedDate)
                }
            }
        }
    }
}

struct DailyCalorieCard: View {
    let caloriesEaten: Int
    let caloriesBurned: Int
    let remainingCalories: Int
    let dailyTarget: Int
    let protein: Double
    let fats: Double
    let carbs: Double
    
    private var progress: Double {
        Double(caloriesEaten) / Double(dailyTarget)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "leaf")
                    .foregroundColor(.green)
                Text("Калории за день")
                    .font(.headline)
                Spacer()
            }
            
            // Круговой прогресс
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(progress > 1.0 ? Color.red : Color.green, lineWidth: 10)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(remainingCalories)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(remainingCalories < 0 ? .red : .primary)
                    Text("ккал осталось")
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 150)
            
            // Статистика
            HStack(spacing: 20) {
                StatItem(
                    title: "Съедено",
                    value: "\(caloriesEaten)",
                    unit: "ккал",
                    color: caloriesEaten > dailyTarget ? .red : .green
                )
                StatItem(
                    title: "Сожжено",
                    value: "\(caloriesBurned)",
                    unit: "ккал",
                    color: .orange
                )
            }
            
            // Макронутриенты
            HStack(spacing: 20) {
                NutrientBar(
                    title: "Углеводы",
                    value: "\(Int(carbs))г",
                    progress: carbs / (Double(dailyTarget) * 0.4 / 4),
                    color: .blue
                )
                NutrientBar(
                    title: "Белки",
                    value: "\(Int(protein))г",
                    progress: protein / (Double(dailyTarget) * 0.3 / 4),
                    color: .red
                )
                NutrientBar(
                    title: "Жиры",
                    value: "\(Int(fats))г",
                    progress: fats / (Double(dailyTarget) * 0.3 / 9),
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct MealRow: View {
    let mealType: MealType
    let calories: Int32
    let targetCalories: Int32
    let meals: [Meal]
    let action: () -> Void
    
    private var progress: Double {
        Double(calories) / Double(targetCalories)
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: mealType.icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text(mealType.rawValue)
                        .font(.headline)
                    Text("\(calories)/\(targetCalories) ккал")
                        .font(.subheadline)
                        .foregroundColor(calories > targetCalories ? .red : .gray)
                }
                
                Spacer()
                
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            if !meals.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(meals, id: \.id) { meal in
                        if let products = meal.products {
                            Text(products.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.gray)
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NutrientBar: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(progress > 1.0 ? .red : .primary)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Rectangle()
                        .fill(progress > 1.0 ? Color.red : color)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
    }
}

struct MealDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let meal: Meal
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Информация")) {
                    HStack {
                        Text("Время")
                        Spacer()
                        Text(meal.date, style: .time)
                    }
                    
                    HStack {
                        Text("Калории")
                        Spacer()
                        Text("\(meal.calories) ккал")
                            .foregroundColor(meal.isOverCalories ? .red : .primary)
                    }
                }
                
                Section(header: Text("Продукты")) {
                    if let products = meal.products {
                        ForEach(Array(products), id: \.id) { product in
                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .font(.headline)
                                
                                HStack {
                                    Text("\(Int(product.portionSize)) \(product.portionUnit)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text("\(product.calories) ккал")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                                
                                HStack {
                                    Text("Б: \(Int(product.protein))г")
                                    Text("Ж: \(Int(product.fats))г")
                                    Text("У: \(Int(product.carbs))г")
                                }
                                .font(.caption)
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
                            Text("Удалить прием пищи")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(meal.mealType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .alert("Удалить прием пищи?", isPresented: $showDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    deleteMeal()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Это действие нельзя отменить")
            }
        }
    }
    
    private func deleteMeal() {
        viewContext.delete(meal)
        try? viewContext.save()
        dismiss()
    }
}

struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        Form {
            DatePicker(
                "Выберите дату",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
        }
        .navigationTitle("Выбор даты")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Готово") {
                    dismiss()
                }
            }
        }
    }
} 