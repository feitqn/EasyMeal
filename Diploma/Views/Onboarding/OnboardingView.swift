import SwiftUI

enum OnboardingStep {
    case goal
    case gender
    case birthday
    case height
    case currentWeight
    case targetWeight
    case completed
}

enum ValidationError: LocalizedError {
    case invalidAge
    case invalidHeight
    case invalidWeight
    case invalidGender
    
    var errorDescription: String? {
        switch self {
        case .invalidAge:
            return "Некорректный возраст"
        case .invalidHeight:
            return "Некорректный рост"
        case .invalidWeight:
            return "Некорректный вес"
        case .invalidGender:
            return "Пол не выбран"
        }
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var currentStep: OnboardingStep = .goal
    @State private var selectedGoal: Goal = .maintenance
    @State private var gender: String = ""
    @State private var birthday: Date = Date()
    @State private var height: Double = 170
    @State private var currentWeight: Double = 70
    @State private var targetWeight: Double = 70
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            switch currentStep {
            case .goal:
                GoalSelectionView(selectedGoal: $selectedGoal)
                    .transition(.slide)
            case .gender:
                GenderSelectionView(gender: $gender)
                    .transition(.slide)
            case .birthday:
                BirthdaySelectionView(birthday: $birthday)
                    .transition(.slide)
            case .height:
                HeightInputView(height: $height)
                    .transition(.slide)
            case .currentWeight:
                WeightInputView(
                    weight: $currentWeight,
                    title: "Enter your current weight",
                    subtitle: "Tracking your weight helps monitor progress and adjust calorie intake."
                )
                .transition(.slide)
            case .targetWeight:
                WeightInputView(
                    weight: $targetWeight,
                    title: "Enter your target weight",
                    subtitle: "Setting a goal weight helps create a sustainable nutrition."
                )
                .transition(.slide)
            case .completed:
                OnboardingCompletedView()
                    .transition(.slide)
            }
            
            if currentStep != .completed {
                Button(action: nextStep) {
                    Text("Continue")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func nextStep() {
        withAnimation {
            switch currentStep {
            case .goal:
                currentStep = .gender
            case .gender:
                if gender.isEmpty {
                    showError = true
                    errorMessage = "Пожалуйста, выберите пол"
                    return
                }
                currentStep = .birthday
            case .birthday:
                currentStep = .height
            case .height:
                currentStep = .currentWeight
            case .currentWeight:
                currentStep = .targetWeight
            case .targetWeight:
                saveUserData()
            case .completed:
                break
            }
        }
    }
    
    private func saveUserData() {
        Task {
            do {
                guard let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year,
                      age >= 0 && age <= 120 else {
                    errorMessage = "Пожалуйста, укажите корректную дату рождения"
                    showError = true
                    return
                }
                
                guard height > 0 && height < 300 else {
                    errorMessage = "Пожалуйста, укажите корректный рост (0-300 см)"
                    showError = true
                    return
                }
                
                guard currentWeight > 0 && currentWeight < 500 else {
                    errorMessage = "Пожалуйста, укажите корректный текущий вес (0-500 кг)"
                    showError = true
                    return
                }
                
                guard targetWeight > 0 && targetWeight < 500 else {
                    errorMessage = "Пожалуйста, укажите корректный целевой вес (0-500 кг)"
                    showError = true
                    return
                }
                
                guard !gender.isEmpty else {
                    errorMessage = "Пожалуйста, выберите пол"
                    showError = true
                    return
                }
                
                // Обновляем данные пользователя через AuthService
                try await authService.updateUserAfterOnboarding(
                    age: age,
                    weight: currentWeight,
                    height: height,
                    goal: selectedGoal
                )
                
                withAnimation {
                    currentStep = .completed
                }
                
                // После успешного сохранения закрываем онбординг
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } catch {
                errorMessage = "Ошибка сохранения данных: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func calculateDailyCalorieTarget(age: Int, weight: Double, height: Double, goal: Goal) -> Int {
        // Базовый расчет калорий (формула Харриса-Бенедикта)
        let bmr: Double
        if gender == "Male" {
            bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
        
        // Корректировка в зависимости от цели
        switch goal {
        case .loss:
            return Int(bmr * 0.85) // Дефицит калорий для похудения
        case .gain:
            return Int(bmr * 1.15) // Профицит калорий для набора веса
        case .maintenance:
            return Int(bmr) // Поддержание веса
        }
    }
} 