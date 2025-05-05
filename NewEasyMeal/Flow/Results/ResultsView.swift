import Foundation
import SwiftUI
import Charts

struct ResultsView: View {
    @StateObject private var viewModel = ResultsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Results")
                .font(.urbanBold(size: 32))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 5)
                .padding(.bottom, 10)
            
            // Analysis type selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.analysisTypes) { type in
                        AnalysisTypeButton(type: type) {
                            viewModel.selectAnalysisType(type)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // User info and progress overview
//                    UserProgressView()
                    
                    // Analysis dashboard
                    AnalysisDashboardView()
                    
                    // Chart
                    AnalysisChartView(viewModel: viewModel)
                    
                    // Stats
                    StatsView(viewModel: viewModel)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct AnalysisTypeButton: View {
    let type: AnalysisType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.title)
                .font(.system(size: 14))
                .foregroundColor(type.isSelected ? .black : .gray)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(type.isSelected ? Color.white : Color.clear)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(type.isSelected ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
    }
}

//struct UserProgressView: View {
//    var body: some View {
//        HStack {
//            // User avatar
//            Image(systemName: "person.circle.fill")
//                .resizable()
//                .frame(width: 40, height: 40)
//                .foregroundColor(.gray)
//            
//            // User info
//            Text("Hi, Name!")
//                .font(.urbanBold(size: 18))
//            
//            Spacer()
//            
//            // Notification bell
//            Image(systemName: "bell")
//                .font(.system(size: 20))
//                .foregroundColor(.gray)
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(15)
//    }
//}

struct AnalysisDashboardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progress Overview")
                    .font(.urbanBold(size: 18))
                
                Spacer()
                
                Button(action: {}) {
                    Text("View All")
                        .font(.urban(size: 14))
                        .foregroundColor(.green)
                        .padding(.horizontal, 5)
                }
            }
            
            Text("Analysis")
                .font(.urban(size: 14))
                .foregroundColor(.gray)
            
            // Metric icons
            HStack(spacing: 20) {
                MetricIconView(icon: "scalemass", title: "Weight", color: .green)
                MetricIconView(icon: "figure.walk", title: "Steps", color: .blue)
                MetricIconView(icon: "fork.knife", title: "Calorie", color: .pink)
                MetricIconView(icon: "flame", title: "Calorie burn", color: .orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
}

struct MetricIconView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

struct AnalysisChartView: View {
    @ObservedObject var viewModel: ResultsViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(getChartTitle())
                .font(.urbanBold(size: 18))
                .padding(.bottom, 5)
            
            if viewModel.selectedAnalysisType.title == "no analysis" {
                Text("No analysis available yet")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color.white)
                    .cornerRadius(15)
            } else {
                ChartView(viewModel: viewModel)
                    .frame(height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
            }
        }
    }
    
    func getChartTitle() -> String {
        switch viewModel.selectedAnalysisType.title {
        case "Results Weight":
            return "Weight Analysis"
        case "Steps Analysis":
            return "Steps Analysis"
        case "Calorie Analysis":
            return "Calorie Analysis"
        case "Calorie burn analysis":
            return "Calorie Burn Analysis"
        case "Water intake analysis":
            return "Water Intake Analysis"
        case "Protein intake analysis":
            return "Protein Intake Analysis"
        default:
            return "Analysis"
        }
    }
}

struct ChartView: View {
    @ObservedObject var viewModel: ResultsViewModel
    
    var data: [AnalysisData] {
        switch viewModel.selectedAnalysisType.title {
        case "Results Weight":
            return viewModel.weightData
        case "Steps Analysis":
            return viewModel.stepsData
        case "Calorie Analysis":
            return viewModel.calorieData
        case "Calorie burn analysis":
            return viewModel.calorieBurnData
        case "Water intake analysis":
            return viewModel.waterIntakeData
        case "Protein intake analysis":
            return viewModel.proteinIntakeData
        default:
            return []
        }
    }
    
    var body: some View {
        VStack {
            // Simple bar chart implementation
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(data.suffix(30)) { item in
                        VStack {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: max((geometry.size.width / 40), 4),
                                       height: calculateBarHeight(item.value, maxHeight: geometry.size.height - 30))
                            
                            if data.count < 15 { // Only show dates for small datasets
                                Text(formatDate(item.date))
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                    .rotationEffect(.degrees(-45))
                                    .fixedSize()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 10)
            }
        }
    }
    
    func calculateBarHeight(_ value: Double, maxHeight: CGFloat) -> CGFloat {
        let maxValue = data.map { $0.value }.max() ?? 1
        let ratio = value / maxValue
        return CGFloat(ratio) * maxHeight
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter.string(from: date)
    }
}

struct StatsView: View {
    @ObservedObject var viewModel: ResultsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("In the last 30 days:")
                .font(.system(size: 16, weight: .medium))
            
            HStack {
                Text("Average per day:")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(formatAverage(viewModel.getAverageForSelectedType()))
                    .font(.system(size: 14, weight: .medium))
            }
            
            if viewModel.selectedAnalysisType.title == "Results Weight" {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Starting weight:")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("75 kg")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    HStack {
                        Text("Goal weight:")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("65 kg")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    HStack {
                        Text("Current weight:")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("67.5 kg")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    HStack {
                        Text("Difference:")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("-7.5 kg")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
    
    func formatAverage(_ value: Double) -> String {
        let unit = getUnitForSelectedType()
        
        if value > 1000 {
            return "\(Int(value)) \(unit)"
        } else if value < 0.1 {
            return String(format: "%.2f \(unit)", value)
        } else if value < 10 {
            return String(format: "%.1f \(unit)", value)
        } else {
            return String(format: "%.0f \(unit)", value)
        }
    }
    
    func getUnitForSelectedType() -> String {
        switch viewModel.selectedAnalysisType.title {
        case "Results Weight":
            return "kg"
        case "Steps Analysis":
            return "steps"
        case "Calorie Analysis":
            return "kcal"
        case "Calorie burn analysis":
            return "kcal"
        case "Water intake analysis":
            return "L"
        case "Protein intake analysis":
            return "g"
        default:
            return ""
        }
    }
}

// Note: TabBar removed as requested - you will use your own implementation

