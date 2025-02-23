import SwiftUI

struct HeightSelectionView: View {
    @Binding var height: Double
    @State private var isCm = true
    
    var displayHeight: Double {
        isCm ? height : height / 2.54 // конвертация в дюймы
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your height")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Used to calculate BMI and determine personalized nutrition goals.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Переключатель единиц измерения
            Picker("Units", selection: $isCm) {
                Text("cm").tag(true)
                Text("ft/in").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            // Слайдер для роста
            HStack {
                Text(String(format: "%.1f", displayHeight))
                    .font(.title)
                    .fontWeight(.bold)
                Text(isCm ? "cm" : "in")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            Slider(value: $height,
                   in: isCm ? 120...220 : 47...87,
                   step: isCm ? 0.5 : 0.5)
                .padding(.horizontal)
        }
        .padding()
    }
} 