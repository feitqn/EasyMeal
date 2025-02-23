import SwiftUI
import Charts

struct ProgressView: View {
    @State private var selectedPeriod = "Week"
    let periods = ["Week", "Month", "Year"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Переключатель периода
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(periods, id: \.self) { period in
                            Text(period).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Карточка с весом
                    WeightProgressCard()
                    
                    // Карточка с калориями
                    CalorieProgressCard()
                    
                    // Карточка с активностью
                    ActivityProgressCard()
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

struct WeightProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weight Progress")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("75 kg")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Target")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("70 kg")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            
            // График прогресса веса
            Chart {
                ForEach(weightData) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Weight", data.weight)
                    )
                    .foregroundStyle(.green)
                    
                    PointMark(
                        x: .value("Date", data.date),
                        y: .value("Weight", data.weight)
                    )
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

struct CalorieProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Calorie Intake")
                .font(.headline)
            
            // График калорий
            Chart {
                ForEach(calorieData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Calories", data.calories)
                    )
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

struct ActivityProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Activity")
                .font(.headline)
            
            // График активности
            Chart {
                ForEach(activityData) { data in
                    LineMark(
                        x: .value("Day", data.day),
                        y: .value("Minutes", data.minutes)
                    )
                    .foregroundStyle(.orange)
                    
                    PointMark(
                        x: .value("Day", data.day),
                        y: .value("Minutes", data.minutes)
                    )
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

// Модели данных для графиков
struct WeightData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct CalorieData: Identifiable {
    let id = UUID()
    let day: String
    let calories: Double
}

struct ActivityData: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Double
}

// Тестовые данные
let weightData = [
    WeightData(date: Date().addingTimeInterval(-6*24*3600), weight: 75.5),
    WeightData(date: Date().addingTimeInterval(-5*24*3600), weight: 75.2),
    WeightData(date: Date().addingTimeInterval(-4*24*3600), weight: 75.0),
    WeightData(date: Date().addingTimeInterval(-3*24*3600), weight: 74.8),
    WeightData(date: Date().addingTimeInterval(-2*24*3600), weight: 74.5),
    WeightData(date: Date().addingTimeInterval(-1*24*3600), weight: 74.3),
    WeightData(date: Date(), weight: 74.0)
]

let calorieData = [
    CalorieData(day: "Mon", calories: 2100),
    CalorieData(day: "Tue", calories: 1950),
    CalorieData(day: "Wed", calories: 2200),
    CalorieData(day: "Thu", calories: 1800),
    CalorieData(day: "Fri", calories: 2000),
    CalorieData(day: "Sat", calories: 2300),
    CalorieData(day: "Sun", calories: 1900)
]

let activityData = [
    ActivityData(day: "Mon", minutes: 45),
    ActivityData(day: "Tue", minutes: 30),
    ActivityData(day: "Wed", minutes: 60),
    ActivityData(day: "Thu", minutes: 45),
    ActivityData(day: "Fri", minutes: 30),
    ActivityData(day: "Sat", minutes: 75),
    ActivityData(day: "Sun", minutes: 45)
] 