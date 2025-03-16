import SwiftUI
import Charts

struct DailyStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let date: Date
    
    @FetchRequest private var meals: FetchedResults<Meal>
    @FetchRequest private var previousMeals: FetchedResults<Meal>
    @FetchRequest private var user: FetchedResults<User>
    
    init(date: Date) {
        self.date = date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let startOfPreviousDay = calendar.date(byAdding: .day, value: -1, to: startOfDay)!
        
        _meals = FetchRequest(
            entity: Meal.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        )
        
        _previousMeals = FetchRequest(
            entity: Meal.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Meal.date, ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", startOfPreviousDay as NSDate, startOfDay as NSDate)
        )
        
        _user = FetchRequest(
            entity: User.entity(),
            sortDescriptors: []
        )
    }
    
    private var totalCaloriesEaten: Int {
        meals.reduce(0) { $0 + Int($1.calories) }
    }
    
    private var previousDayCalories: Int {
        previousMeals.reduce(0) { $0 + Int($1.calories) }
    }
    
    private var caloriesDifference: Int {
        totalCaloriesEaten - previousDayCalories
    }
    
    private var totalCaloriesBurned: Int {
        user.first?.workouts?.reduce(0) { $0 + Int($1.caloriesBurned) } ?? 0
    }
    
    private var remainingCalories: Int {
        Int(user.first?.dailyCalorieTarget ?? 2176) - totalCaloriesEaten + totalCaloriesBurned
    }
    
    private var totalProtein: Double {
        meals.reduce(0) { $0 + $1.totalProtein }
    }
    
    private var previousDayProtein: Double {
        previousMeals.reduce(0) { $0 + $1.totalProtein }
    }
    
    private var totalFats: Double {
        meals.reduce(0) { $0 + $1.totalFats }
    }
    
    private var previousDayFats: Double {
        previousMeals.reduce(0) { $0 + $1.totalFats }
    }
    
    private var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.totalCarbs }
    }
    
    private var previousDayCarbs: Double {
        previousMeals.reduce(0) { $0 + $1.totalCarbs }
    }
    
    private var mealsGroupedByType: [MealType: [Meal]] {
        Dictionary(grouping: meals) { meal in
            meal.mealType
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // График калорий по приемам пищи
                CaloriesChart(meals: Array(meals), previousMeals: Array(previousMeals))
                    .frame(height: 200)
                    .padding()
                
                // Общая статистика
                HStack {
                    StatCard(
                        title: "Съедено",
                        value: totalCaloriesEaten,
                        previousValue: previousDayCalories,
                        unit: "ккал",
                        icon: "fork.knife",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Сожжено",
                        value: totalCaloriesBurned,
                        unit: "ккал",
                        icon: "flame",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Осталось",
                        value: remainingCalories,
                        unit: "ккал",
                        icon: "arrow.forward",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Макронутриенты
                MacronutrientsView(
                    protein: totalProtein,
                    previousProtein: previousDayProtein,
                    fats: totalFats,
                    previousFats: previousDayFats,
                    carbs: totalCarbs,
                    previousCarbs: previousDayCarbs,
                    targetCalories: Double(user.first?.dailyCalorieTarget ?? 2176)
                )
                .padding()
                
                // Рекомендации
                if let recommendations = getNutritionRecommendations() {
                    RecommendationsView(recommendations: recommendations)
                        .padding()
                }
                
                // Приемы пищи
                VStack(alignment: .leading, spacing: 15) {
                    Text("Приемы пищи")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        if let meals = mealsGroupedByType[mealType] {
                            MealTypeSection(
                                mealType: mealType,
                                meals: meals,
                                targetCalories: mealType.targetCalories
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .navigationTitle(date.formatted(date: .complete, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(), value: meals.count)
    }
    
    private func getNutritionRecommendations() -> [String]? {
        var recommendations: [String] = []
        
        // Проверяем общее потребление калорий
        if totalCaloriesEaten > Int(user.first?.dailyCalorieTarget ?? 2176) {
            recommendations.append("Сегодня вы превысили дневную норму калорий. Попробуйте выбирать менее калорийные продукты.")
        } else if totalCaloriesEaten < Int(user.first?.dailyCalorieTarget ?? 2176) * 0.7 {
            recommendations.append("Сегодня вы потребили слишком мало калорий. Убедитесь, что вы едите достаточно для поддержания здоровья.")
        }
        
        // Проверяем баланс макронутриентов
        let targetProtein = Double(user.first?.dailyCalorieTarget ?? 2176) * 0.3 / 4
        if totalProtein < targetProtein * 0.8 {
            recommendations.append("Рекомендуется увеличить потребление белка. Добавьте в рацион больше мяса, рыбы или бобовых.")
        }
        
        let targetFats = Double(user.first?.dailyCalorieTarget ?? 2176) * 0.3 / 9
        if totalFats > targetFats * 1.2 {
            recommendations.append("Потребление жиров превышает норму. Старайтесь выбирать менее жирные продукты.")
        }
        
        return recommendations.isEmpty ? nil : recommendations
    }
}

struct CaloriesChart: View {
    let meals: [Meal]
    let previousMeals: [Meal]
    @State private var showPreviousDay = false
    
    var body: some View {
        VStack {
            Toggle("Сравнить со вчерашним днем", isPresented: $showPreviousDay)
                .padding(.horizontal)
            
            Chart {
                ForEach(meals, id: \.id) { meal in
                    BarMark(
                        x: .value("Время", meal.date, unit: .hour),
                        y: .value("Калории", meal.calories)
                    )
                    .foregroundStyle(by: .value("День", "Сегодня"))
                }
                
                if showPreviousDay {
                    ForEach(previousMeals, id: \.id) { meal in
                        BarMark(
                            x: .value("Время", meal.date, unit: .hour),
                            y: .value("Калории", meal.calories)
                        )
                        .foregroundStyle(by: .value("День", "Вчера"))
                        .opacity(0.5)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    var previousValue: Int?
    let unit: String
    let icon: String
    let color: Color
    
    private var difference: Int? {
        guard let previousValue = previousValue else { return nil }
        return value - previousValue
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if let difference = difference {
                HStack(spacing: 2) {
                    Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                    Text("\(abs(difference))")
                }
                .font(.caption2)
                .foregroundColor(difference >= 0 ? .red : .green)
                .transition(.scale.combined(with: .opacity))
            }
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MacronutrientsView: View {
    let protein: Double
    let previousProtein: Double
    let fats: Double
    let previousFats: Double
    let carbs: Double
    let previousCarbs: Double
    let targetCalories: Double
    
    private var targetProtein: Double {
        targetCalories * 0.3 / 4 // 30% калорий из белков
    }
    
    private var targetFats: Double {
        targetCalories * 0.3 / 9 // 30% калорий из жиров
    }
    
    private var targetCarbs: Double {
        targetCalories * 0.4 / 4 // 40% калорий из углеводов
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Макронутриенты")
                .font(.headline)
            
            MacroProgressBar(
                title: "Белки",
                current: protein,
                previous: previousProtein,
                target: targetProtein,
                color: .red
            )
            
            MacroProgressBar(
                title: "Жиры",
                current: fats,
                previous: previousFats,
                target: targetFats,
                color: .yellow
            )
            
            MacroProgressBar(
                title: "Углеводы",
                current: carbs,
                previous: previousCarbs,
                target: targetCarbs,
                color: .blue
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MacroProgressBar: View {
    let title: String
    let current: Double
    let previous: Double
    let target: Double
    let color: Color
    
    private var progress: Double {
        min(current / target, 1.0)
    }
    
    private var previousProgress: Double {
        min(previous / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(current))/\(Int(target))г")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    // Вчерашний прогресс
                    Rectangle()
                        .fill(color.opacity(0.3))
                        .frame(width: geometry.size.width * previousProgress)
                    
                    // Текущий прогресс
                    Rectangle()
                        .fill(progress > 1.0 ? Color.red : color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
            
            // Разница с предыдущим днем
            if abs(current - previous) > 1 {
                HStack {
                    Image(systemName: current >= previous ? "arrow.up" : "arrow.down")
                    Text("\(String(format: "%.1f", abs(current - previous)))г")
                }
                .font(.caption2)
                .foregroundColor(current >= previous ? .red : .green)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct RecommendationsView: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Рекомендации")
                .font(.headline)
            
            ForEach(recommendations, id: \.self) { recommendation in
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text(recommendation)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MealTypeSection: View {
    let mealType: MealType
    let meals: [Meal]
    let targetCalories: Int
    
    private var totalCalories: Int {
        meals.reduce(0) { $0 + Int($1.calories) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(.green)
                Text(mealType.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(totalCalories)/\(targetCalories) ккал")
                    .foregroundColor(totalCalories > targetCalories ? .red : .gray)
            }
            
            ForEach(meals, id: \.id) { meal in
                if let products = meal.products {
                    Text(products.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
} 