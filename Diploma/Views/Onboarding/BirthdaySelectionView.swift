import SwiftUI

struct BirthdaySelectionView: View {
    @Binding var birthday: Date
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select your birthday")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your age influences metabolism and daily calorie needs.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            DatePicker(
                "Birthday",
                selection: $birthday,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .padding()
        }
    }
} 