import SwiftUI

struct HealthGoalsView: View {
    @State private var goal = "Lose weight"
    @State private var height = "170 cm"
    @State private var currentWeight = "70 kg"
    @State private var targetWeight = "60 kg"
    @State private var weeklyGoal = "-0.5 kg"
    @State private var dailyCalories = "2100 kcal"
    @State private var steps = "2100 kcal"  
    @State private var water = "2100 kcal"  // Note: this appears to be an error in the UI mockup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
             
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.gray.opacity(0.2), radius: 2)
                }
                
                Spacer()
                
                Button(action: {
                    // Confirm button action
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            // Title
            Text("Health goals")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Form Fields
            ScrollView {
                VStack(spacing: 20) {
                    goalField(title: "Goal", value: $goal, icon: "flag.fill")
                    formField(title: "Height", value: $height, icon: "ruler.fill")
                    formField(title: "Current weight", value: $currentWeight, icon: "scalemass.fill")
                    formField(title: "Target weight", value: $targetWeight, icon: "scalemass.fill")
                    formField(title: "Goal for week", value: $weeklyGoal, icon: "chart.bar.fill")
                    formField(title: "Daily calories", value: $dailyCalories, icon: "flame.fill")
                    formField(title: "Steps", value: $steps, icon: "figure.walk")
                    formField(title: "Water", value: $water, icon: "drop.fill")
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 16)
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    func formField(title: String, value: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField("", text: value)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
    
    func goalField(title: String, value: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                Text(value.wrappedValue)
                    .font(.system(size: 16))
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
}
