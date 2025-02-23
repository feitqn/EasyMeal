import SwiftUI

struct RegistrationSuccessView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var showOnboarding = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Иконка успеха
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            // Заголовок
            VStack(spacing: 12) {
                Text("Регистрация успешна!")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Давайте настроим ваш профиль\nдля персонализированных рекомендаций.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Кнопка
            Button {
                showOnboarding = true
            } label: {
                Text("Продолжить")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            authService.isAuthenticated = true
            authService.isOnboardingCompleted = true
        }) {
            OnboardingView()
        }
    }
} 