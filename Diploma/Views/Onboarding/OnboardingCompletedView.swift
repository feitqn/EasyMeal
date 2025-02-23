import SwiftUI

struct OnboardingCompletedView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Your plan is ready!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Work towards your goal and enjoy\nevery meal along the way.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                authService.isOnboardingCompleted = true
            } label: {
                Text("Get Started")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
} 