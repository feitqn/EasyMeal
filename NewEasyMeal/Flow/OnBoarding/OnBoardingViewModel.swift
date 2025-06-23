import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case goal, gender, birthday, height, currentWeight, targetWeight, loading, done
}

// Gender.swift
enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    
    var id: String { rawValue }
    
    var image: Image {
        switch self {
        case .male:
            Image("male")
        case .female:
            Image("female")
        }
    }
}

// OnboardingViewModel.swift
class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .goal
    @Published var selectedGoal: WeightGoal?
    @Published var selectedGender: Gender?
    @Published var birthdate: Date = Date()
    @Published var height: Double = 170
    @Published var weight: Double = 70
    @Published var targetWeight: Double = 65
    var profile: UserProfile? = UserManager.shared.getUserProfile() ?? nil
    
    var isContinueEnabled: Bool {
        switch step {
        case .goal: return selectedGoal != nil
        case .gender: return selectedGender != nil
        case .birthday: return true
        case .height: return true
        case .currentWeight: return true
        case .targetWeight: return true
        case .loading: return false
        case .done: return true
        }
    }

    func next() {
        switch step {
        case .goal:
            profile?.currentGoal = selectedGoal?.rawValue
            step = .gender
        case .gender:
            profile?.gender = selectedGender?.rawValue
            step = .birthday
        case .birthday:
            profile?.birthDate = birthdate
            step = .height
        case .height:
            profile?.height = Int(height)
            step = .currentWeight
        case .currentWeight:
            profile?.weight = weight
            step = .targetWeight
        case .targetWeight:
            profile?.targetWeight = targetWeight
            step = .loading
            finishOnboarding()
        case .loading: break
        case .done: break
        }
    }
    
    func finishOnboarding() {
        Task {
            try await APIHelper.shared.finishOnbooarding(for: profile)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.step = .done
            }
        }
    }
}
