import SwiftUI

struct WeightInputView: View {
    @Binding var weight: Double
    let title: String
    let subtitle: String
    @State private var useKilograms = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack {
                TextField("Weight", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                
                Picker("Unit", selection: $useKilograms) {
                    Text("kg").tag(true)
                    Text("lbs").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: useKilograms) { newValue in
                    weight = newValue ? weight * 0.453592 : weight / 0.453592
                }
            }
            .padding()
        }
    }
} 