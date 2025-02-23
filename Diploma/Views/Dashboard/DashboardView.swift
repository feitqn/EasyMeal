import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    CaloriesCardView()
                    WaterTrackerView()
                    StepsCounterView()
                }
                .padding()
            }
            .navigationTitle("EasyMeal")
        }
    }
}

struct CaloriesCardView: View {
    var body: some View {
        VStack {
            Text("Калории")
                .font(.headline)
            Text("1200 / 2000")
                .font(.title)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}

struct WaterTrackerView: View {
    @State private var waterIntake = 0
    let waterTarget = 2000 // мл
    
    var body: some View {
        VStack {
            Text("Вода")
                .font(.headline)
            Text("\(waterIntake) / \(waterTarget) мл")
                .font(.title)
                .bold()
            Button("+ 250 мл") {
                waterIntake += 250
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StepsCounterView: View {
    @State private var steps = 0
    let stepsTarget = 10000
    
    var body: some View {
        VStack {
            Text("Шаги")
                .font(.headline)
            Text("\(steps) / \(stepsTarget)")
                .font(.title)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
} 