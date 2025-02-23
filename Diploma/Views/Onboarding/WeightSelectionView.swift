import SwiftUI

struct WeightSelectionView: View {
    @Binding var weight: Double
    @State private var isKg = true
    
    var displayWeight: Double {
        isKg ? weight : weight * 2.20462 // конвертация в фунты
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your current weight")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Tracking your weight helps monitor progress and adjust calorie intake.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Переключатель единиц измерения
            Picker("Units", selection: $isKg) {
                Text("kg").tag(true)
                Text("lbs").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            // Слайдер для веса
            HStack {
                Text(String(format: "%.1f", displayWeight))
                    .font(.title)
                    .fontWeight(.bold)
                Text(isKg ? "kg" : "lbs")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            Slider(value: $weight,
                   in: isKg ? 30...200 : 66...440,
                   step: isKg ? 0.1 : 0.2)
                .padding(.horizontal)
        }
        .padding()
    }
} 