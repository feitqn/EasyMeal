import SwiftUI

struct HeightInputView: View {
    @Binding var height: Double
    @State private var useCentimeters = true
    
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
            
            VStack {
                TextField("Height", value: $height, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                
                Picker("Unit", selection: $useCentimeters) {
                    Text("cm").tag(true)
                    Text("ft/in").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: useCentimeters) { newValue in
                    height = newValue ? height * 2.54 : height / 2.54
                }
                .padding()
            }
        }
    }
} 