import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Калории")) {
                    WeeklyCaloriesChart()
                }
                
                Section(header: Text("Вода")) {
                    WeeklyWaterChart()
                }
                
                Section(header: Text("Шаги")) {
                    WeeklyStepsChart()
                }
            }
            .navigationTitle("Статистика")
        }
    }
}

struct WeeklyCaloriesChart: View {
    var body: some View {
        VStack {
            Text("График калорий")
            // Здесь будет график
        }
        .frame(height: 200)
    }
}

struct WeeklyWaterChart: View {
    var body: some View {
        VStack {
            Text("График потребления воды")
            // Здесь будет график
        }
        .frame(height: 200)
    }
}

struct WeeklyStepsChart: View {
    var body: some View {
        VStack {
            Text("График шагов")
            // Здесь будет график
        }
        .frame(height: 200)
    }
} 