import SwiftUI
import Charts
import Combine
    
// MARK: - Main View
struct ProgressOverviewView: View {
    @ObservedObject var viewModel: ProgressOverviewViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                analysisButtonsSection
                
                if viewModel.selectedAnalysis == 0 {
                    weightAnalysisSection
                } else if viewModel.selectedAnalysis == 1 {
                    stepsAnalysisSection
                } else if viewModel.selectedAnalysis == 2 {
                    calorieAnalysisSection
                } else if viewModel.selectedAnalysis == 3 {
                    burnAnalysisSection
                }
                
                
                Spacer(minLength: 100) // Bottom padding
            }
            .padding(.top, 1)
            .padding(.horizontal, 20)
        }
        .background(Color.backColor)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress Overview")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Analysis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
//            Button(action: {
//                viewModel.refreshData()
//            }) {
//                HStack(spacing: 4) {
//                    Text("View All")
//                        .font(.system(size: 16, weight: .medium))
//                    Image(systemName: "arrow.right")
//                        .font(.system(size: 12))
//                }
//                .foregroundColor(.green)
//            }
        }
    }
    
    // MARK: - Analysis Buttons Section
    private var analysisButtonsSection: some View {
        HStack(spacing: 16) {
            ForEach(Array(viewModel.analysisTypes.enumerated()), id: \.element.id) { index, type in
                Button(action: {
                    viewModel.selectAnalysis(index)
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedAnalysis == index ? type.color : Color(.systemGray5))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: type.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(viewModel.selectedAnalysis == index ? .white : .gray)
                        }
                        
                        Text(type.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Weight Analysis Section
    private var weightAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight Analysis")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(viewModel.weeksToTarget) weeks until you reach your target.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // Weight Chart
            VStack(spacing: 16) {
                if #available(iOS 16.0, *) {
                    ScrollableChartView {
                        Chart(viewModel.weightData) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Weight", data.weight)
                            )
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .symbol(.circle)
                            .symbolSize(30)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .stride(by: 2)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel()
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYScale(domain: 60...72)
                    }
                    .frame(height: 220)
                } else {
                    ScrollableSimpleChart {
                        SimpleLineChart(data: viewModel.weightData.map { $0.weight })
                    }
                    .frame(height: 220)
                }
            
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            
            // Weight Statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("In the last 30 days:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 6) {
                    StatRow(title: "Starting weight:", value: String(format: "%.0f kg", viewModel.startingWeight))
                    StatRow(title: "Goal Weight:", value: String(format: "%.0f kg", viewModel.goalWeight))
                    StatRow(title: "Current Weight:", value: String(format: "%.1f kg", viewModel.currentWeight))
                    StatRow(title: "Difference:", value: String(format: "%.1f kg", viewModel.weightDifference), valueColor: .green)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Steps Analysis Section
    private var stepsAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steps Analysis")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            // Steps Chart
            VStack(spacing: 16) {
                if #available(iOS 16.0, *) {
                    ScrollableChartView {
                        Chart(viewModel.stepsData) { data in
                            BarMark(
                                x: .value("Date", data.date),
                                y: .value("Steps", data.steps)
                            )
                            .foregroundStyle(.green)
                            .cornerRadius(2)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .stride(by: 2000)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel()
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 220)
                } else {
                    ScrollableSimpleChart {
                        SimpleBarChart(data: viewModel.stepsData.map { Double($0.steps) })
                    }
                    .frame(height: 220)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            
            // Steps Statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("In the last 30 days:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 6) {
                    StatRow(title: "Average per day:", value: "\(viewModel.averageStepsPerDay)", valueColor: .blue)
                    StatRow(title: "Goal:", value: "\(viewModel.stepsGoal)")
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
    
    private var calorieAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calorie Analysis")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                if #available(iOS 16.0, *) {
                    ScrollableChartView {
                        Chart(viewModel.calorieData, id: \.date) { entry in
                            BarMark(
                                x: .value("Date", entry.date),
                                y: .value("Calories", entry.value)
                            )
                            .foregroundStyle(.blue)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .stride(by: 500))
                        }
                    }
                    .frame(height: 220)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 12) {
                Text("In the last 30 days:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    StatRow(title: "Total Calories:", value: "\(viewModel.totalCalories)", valueColor: .blue)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    private var burnAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calories Burned")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                if #available(iOS 16.0, *) {
                    ScrollableChartView {
                        Chart(viewModel.calorieBurnData, id: \.date) { entry in
                            BarMark(
                                x: .value("Date", entry.date),
                                y: .value("Burned", entry.value)
                            )
                            .foregroundStyle(.orange)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .stride(by: 200))
                        }
                    }
                    .frame(height: 220)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 12) {
                Text("In the last 30 days:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    StatRow(title: "Total burned", value: "\(viewModel.totalBurned)", valueColor: .orange)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}

// MARK: - Scrollable Chart Views
@available(iOS 16.0, *)
struct ScrollableChartView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = max(geometry.size.width * 2.5, 30 * 10) // Минимум 10px между точками для 30 дней
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        content
                            .frame(width: totalWidth)
                            .id("chart")
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 60) // Дополнительный отступ справа
                }
                .onAppear {
                    // Прокручиваем к правому краю (последние дни)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("chart", anchor: .trailing)
                        }
                    }
                }
            }
        }
    }
}

struct ScrollableSimpleChart<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = max(geometry.size.width * 2.5, 30 * 10) // Минимум 10px между точками
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    content
                        .frame(width: totalWidth)
                }
                .padding(.leading, 20)
                .padding(.trailing, 60) // Дополнительный отступ справа
            }
            .defaultScrollAnchor(.trailing) // Показываем последние данные
        }
    }
}

// MARK: - Helper Views
struct StatRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text("• \(title)")
                .font(.system(size: 15))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Fallback Charts for iOS 15
struct SimpleLineChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = maxValue - minValue
            let minSpacing: CGFloat = 10 // Минимальное расстояние между точками 10px
            let totalWidth = max(geometry.size.width, CGFloat(data.count) * minSpacing)
            
            Path { path in
                for (index, value) in data.enumerated() {
                    let x = totalWidth * CGFloat(index) / CGFloat(data.count - 1)
                    let y = geometry.size.height * (1 - CGFloat((value - minValue) / range))
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.green, lineWidth: 2)
            .frame(width: totalWidth)
        }
    }
}

struct SimpleBarChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minSpacing: CGFloat = 10 // Минимальное расстояние между барами 10px
            let totalWidth = max(geometry.size.width, CGFloat(data.count) * minSpacing)
            let barWidth = (totalWidth / CGFloat(data.count)) - 2
            
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<data.count, id: \.self) { index in
                    Rectangle()
                        .fill(Color.green)
                        .frame(
                            width: max(barWidth, 8),
                            height: geometry.size.height * CGFloat(data[index] / maxValue)
                        )
                }
            }
            .frame(width: totalWidth)
        }
    }
}
