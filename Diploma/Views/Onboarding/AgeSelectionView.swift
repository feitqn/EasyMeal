import SwiftUI

struct AgeSelectionView: View {
    @Binding var age: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select your age")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your age influences metabolism and daily calorie needs.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Picker для выбора возраста
            Picker("Age", selection: $age) {
                ForEach(15...100, id: \.self) { year in
                    Text("\(year) years").tag(year)
                }
            }
            .pickerStyle(.wheel)
            .padding()
        }
    }
} 