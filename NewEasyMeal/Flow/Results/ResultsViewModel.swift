import Foundation
import SwiftUI
import Charts

// MARK: - Models
struct AnalysisType: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let isSelected: Bool
    
    static let samples = [
        AnalysisType(title: "Results Weight", isSelected: true),
        AnalysisType(title: "Steps Analysis", isSelected: false),
        AnalysisType(title: "Calorie Analysis", isSelected: false),
        AnalysisType(title: "Calorie burn analysis", isSelected: false),
        AnalysisType(title: "Water intake analysis", isSelected: false),
        AnalysisType(title: "Protein intake analysis", isSelected: false),
        AnalysisType(title: "no analysis", isSelected: false)
    ]
}

struct AnalysisData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    
    static func generateSampleData(count: Int, maxValue: Double, minValue: Double = 0) -> [AnalysisData] {
        let calendar = Calendar.current
        var data: [AnalysisData] = []
        
        for i in 0..<count {
            let date = calendar.date(byAdding: .day, value: -count + i, to: Date()) ?? Date()
            let value = Double.random(in: minValue...maxValue)
            data.append(AnalysisData(date: date, value: value))
        }
        
        return data
    }
}



class ResultsViewModel: ObservableObject {
    @Published var selectedAnalysisType: AnalysisType = AnalysisType.samples[0]
    @Published var analysisTypes: [AnalysisType] = AnalysisType.samples
    @Published var weightData: [AnalysisData] = AnalysisData.generateSampleData(count: 30, maxValue: 90, minValue: 50)
    @Published var stepsData: [AnalysisData] = AnalysisData.generateSampleData(count: 30, maxValue: 10000)
    @Published var calorieData: [AnalysisData] = AnalysisData.generateSampleData(count: 30, maxValue: 2500, minValue: 1200)
    @Published var calorieBurnData: [AnalysisData] = AnalysisData.generateSampleData(count: 30, maxValue: 800, minValue: 100)
    @Published var waterIntakeData: [AnalysisData] = AnalysisData.generateSampleData(count: 30, maxValue: 2.5, minValue: 0.5)
    @Published var proteinIntakeData: [AnalysisData] = AnalysisData.generateSampleData(count: 30, maxValue: 100, minValue: 20)
    
    func selectAnalysisType(_ type: AnalysisType) {
        for i in 0..<analysisTypes.count {
            analysisTypes[i] = AnalysisType(title: analysisTypes[i].title, isSelected: analysisTypes[i].title == type.title)
        }
        selectedAnalysisType = type
    }
    
    func getAverageForSelectedType() -> Double {
        switch selectedAnalysisType.title {
        case "Results Weight":
            return weightData.map { $0.value }.reduce(0, +) / Double(weightData.count)
        case "Steps Analysis":
            return stepsData.map { $0.value }.reduce(0, +) / Double(stepsData.count)
        case "Calorie Analysis":
            return calorieData.map { $0.value }.reduce(0, +) / Double(calorieData.count)
        case "Calorie burn analysis":
            return calorieBurnData.map { $0.value }.reduce(0, +) / Double(calorieBurnData.count)
        case "Water intake analysis":
            return waterIntakeData.map { $0.value }.reduce(0, +) / Double(waterIntakeData.count)
        case "Protein intake analysis":
            return proteinIntakeData.map { $0.value }.reduce(0, +) / Double(proteinIntakeData.count)
        default:
            return 0
        }
    }
}
