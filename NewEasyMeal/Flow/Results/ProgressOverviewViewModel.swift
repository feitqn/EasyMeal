import SwiftUI
import UIKit

// MARK: - Models
struct AnalysisType: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
}

struct WeightData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct StepsData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

@MainActor// MARK: - ViewModel
final class ProgressOverviewViewModel: ObservableObject {
    @Published var selectedAnalysis: Int = 0
    @Published var weightData: [WeightData] = []
    @Published var stepsData: [StepsData] = []
    
    // Weight statistics
    @Published var startingWeight: Double = 70.0
    @Published var goalWeight: Double = 60.0
    @Published var currentWeight: Double = 67.8
    @Published var weightDifference: Double = 2.2
    @Published var weeksToTarget: Int = 20
    
    // Steps statistics
    @Published var averageStepsPerDay: Int = 3200
    @Published var stepsGoal: Int = 10000

    @Published var calorieData: [(date: Date, value: Int)] = []
    @Published var calorieBurnData: [(date: Date, value: Int)] = []

    @Published var totalCalories: Int = 0
    @Published var totalBurned: Int = 0

    @Published var calorieGoal: Int = 2000
    @Published var burnGoal: Int = 500
    
    @Published var data: [String: FoodDiary] = [:]
    
    
    let analysisTypes = [
        AnalysisType(title: "Weight", icon: "scalemass", color: .green, isSelected: true),
        AnalysisType(title: "Steps", icon: "figure.walk", color: .green, isSelected: false),
        AnalysisType(title: "Calorie", icon: "heart.fill", color: .blue, isSelected: false),
        AnalysisType(title: "Calorie burn", icon: "flame.fill", color: .orange, isSelected: false)
    ]
    
    func selectAnalysis(_ index: Int) {
        selectedAnalysis = index
    }
    
    private func generateSampleData(from data: [String: FoodDiary]) {
        let calendar = Calendar.current
        let now = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Получаем отсортированные даты
        let sortedDates = data.keys.compactMap { dateFormatter.date(from: $0) }.sorted()
        guard let startDate = sortedDates.first else { return }
        
        // Собираем все даты от startDate до now
        var allDates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= now {
            allDates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        // Генерация веса
        weightData = allDates.enumerated().map { index, date in
            let dateString = dateFormatter.string(from: date)
            let baseWeight = data[dateString]?.currentWeight ?? 70.0
            
            if index == 0 {
                startingWeight = baseWeight
                currentWeight = UserManager.shared.getUserProfile()?.weight ?? baseWeight
                goalWeight = UserManager.shared.getUserProfile()?.targetWeight ?? 60.0
                weightDifference = currentWeight - startingWeight
            }

            let daysSinceStart = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            let progress = Double(daysSinceStart) * 0.07
            let randomVariation = Double.random(in: -0.5...0.5)
            let weight = baseWeight - progress + randomVariation

            return WeightData(date: date, weight: max(weight, 60.0))
        }.reversed()
        
        // Генерация шагов
        stepsData = allDates.enumerated().map { index, date in
            let dateString = dateFormatter.string(from: date)
            let steps = data[dateString]?.steps?.current ?? 0
            
            return StepsData(date: date, steps: steps)
        }.reversed()
        
        // Пересчет среднего после генерации
        let totalSteps = stepsData.map { $0.steps }.reduce(0, +)
        if !stepsData.isEmpty {
            averageStepsPerDay = totalSteps / stepsData.count
        }
        
        // Генерация калорий и сожжённых калорий
        calorieData = allDates.compactMap { date in
            let dateString = dateFormatter.string(from: date)
            let value = data[dateString]?.eatenCalories ?? 0
            if date == allDates.first {
//                calorieGoal = data[dateString]?.eatenCalories?.target ?? 2000
            }
            return (date, value)
        }.reversed()

        calorieBurnData = allDates.compactMap { date in
            let dateString = dateFormatter.string(from: date)
            let value = data[dateString]?.burnedCalories ?? 0
            if date == allDates.first {
//                burnGoal = data[dateString]?.burned?.target ?? 500
            }
            return (date, value)
        }.reversed()

        // Средние значения
        if !calorieData.isEmpty {
            totalCalories = calorieData.map { $0.value }.reduce(0, +)
        }
        if !calorieBurnData.isEmpty {
            totalBurned = calorieBurnData.map { $0.value }.reduce(0, +)
        }
    }
    
    private func calculateStatistics() {
        if let firstWeight = weightData.first?.weight,
           let lastWeight = weightData.last?.weight  {
            startingWeight = firstWeight
            currentWeight = lastWeight
            weightDifference = firstWeight - lastWeight
        }
        
        let totalSteps = stepsData.map { $0.steps }.reduce(0, +)
        if !stepsData.isEmpty {
            averageStepsPerDay = totalSteps / stepsData.count
        }
    }
    
    func refreshData() {
        generateSampleData(from: data)
        calculateStatistics()
    }
    
    func getFoodDiary() {
        Task {
            do {
                let res: [String: FoodDiary] = try await APIHelper.shared.fetchFoodDiaries()
                data = res
                generateSampleData(from: data)
//                calculateStatistics()
            } catch {
                print(error)
            }
        }
    }
}
