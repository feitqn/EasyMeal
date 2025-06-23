import SwiftUI

struct HealthGoalsView: View {
    @ObservedObject var viewModel = HealthGoalsViewModel()
    var onTapExit: (() -> Void)?
    
    enum PickerType: Identifiable {
        case goal, height, currentWeight, targetWeight, weeklyGoal
        
        var id: Int {
            hashValue
        }
    }
    
    @State private var activePicker: PickerType?
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Button(action: { onTapExit?() }) {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .gray.opacity(0.2), radius: 2)
                }
                Spacer()
                Button(action: {
                    viewModel.saveChanges {
                        onTapExit?()
                    }
                    // Можно вызывать APIHelper.shared.updateUserProfileFields здесь
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            Text("Health Goals")
                .font(.largeTitle).bold()
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    pickerRow(title: "Goal", value: viewModel.goal, icon: "flag.fill", pickerType: .goal)
                    pickerRow(title: "Height", value: "\(viewModel.height) cm", icon: "ruler.fill", pickerType: .height)
                    pickerRow(title: "Current Weight", value: "\(viewModel.currentWeight) kg", icon: "scalemass.fill", pickerType: .currentWeight)
                    pickerRow(title: "Target Weight", value: "\(viewModel.targetWeight) kg", icon: "scalemass.fill", pickerType: .targetWeight)
//                    pickerRow(title: "Weekly Goal", value: viewModel.weeklyGoal, icon: "chart.bar.fill", pickerType: .weeklyGoal)
//                    displayOnlyRow(title: "Daily Calories", value: "\(viewModel.dailyCalories) kcal", icon: "flame.fill")
//                    displayOnlyRow(title: "Steps", value: "\(viewModel.steps)", icon: "figure.walk")
//                    displayOnlyRow(title: "Water", value: "\(viewModel.water) ml", icon: "drop.fill")
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
        .sheet(item: $activePicker) { type in
            sheetForPicker(type)
                .presentationDetents([.fraction(0.3)])
        }
    }
    
    func pickerRow(title: String, value: String, icon: String, pickerType: PickerType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Button {
                activePicker = pickerType
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    Text(value)
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
    
    func displayOnlyRow(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text(value)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
    
    @ViewBuilder
    func sheetForPicker(_ type: PickerType) -> some View {
        VStack {
            Text("Select value").font(.headline).padding()
            
            switch type {
            case .goal:
                Picker("Goal", selection: $viewModel.goal) {
                    ForEach(["Lose weight", "Maintain", "Gain weight"], id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                
            case .height:
                Picker("Height", selection: $viewModel.height) {
                    ForEach(120...250, id: \.self) {
                        Text("\($0) cm")
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                
            case .currentWeight:
                Picker("Current", selection: $viewModel.currentWeight) {
                    ForEach(Array(stride(from: 30.0, through: 200.0, by: 0.5)), id: \.self) {
                        Text(String(format: "%.1f kg", $0))
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                
            case .targetWeight:
                Picker("Target", selection: $viewModel.targetWeight) {
                    ForEach(Array(stride(from: 30.0, through: 200.0, by: 0.5)), id: \.self) {
                        Text(String(format: "%.1f kg", $0))
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                
            case .weeklyGoal:
                Picker("Weekly Goal", selection: $viewModel.weeklyGoal) {
                    ForEach(["-1.0 kg", "-0.5 kg", "-0.25 kg", "Maintain", "+0.25 kg", "+0.5 kg", "+1.0 kg"], id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }
            
            Button("Done") {
                activePicker = nil
            }
            .padding()
        }
    }
}
