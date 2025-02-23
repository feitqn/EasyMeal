import SwiftUI

struct GenderSelectionView: View {
    @Binding var gender: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select your gender")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This helps provide more accurate calorie and nutrition recommendations.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                GenderButton(
                    gender: "Male",
                    icon: "👨",
                    isSelected: gender == "Male",
                    action: { gender = "Male" }
                )
                
                GenderButton(
                    gender: "Female",
                    icon: "👩",
                    isSelected: gender == "Female",
                    action: { gender = "Female" }
                )
            }
            .padding()
        }
    }
}

struct GenderButton: View {
    let gender: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon)
                    .font(.title2)
                Text(gender)
                    .font(.title3)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
} 