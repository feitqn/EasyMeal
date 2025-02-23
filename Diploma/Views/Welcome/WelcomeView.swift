import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showLogin = false
    @State private var showRegistration = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Верхняя часть с изображениями продуктов
            Image("welcome-food")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 300)
            
            // Логотип
            Image("leaf-logo")
                .resizable()
                .frame(width: 50, height: 50)
            
            // Приветственный текст
            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.system(size: 40, weight: .bold))
                Text("EasyMeal")
                    .foregroundColor(.green)
                    .font(.system(size: 40, weight: .bold))
            }
            
            // Подзаголовок
            Text("Eat Better, Count Smarter, Live Healthier")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Кнопки
            VStack(spacing: 15) {
                Button(action: { showLogin = true }) {
                    Text("Login")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(30)
                }
                
                Button(action: { showRegistration = true }) {
                    Text("Register")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.green, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showRegistration) {
            SignUpView()
                .environmentObject(authService)
        }
    }
}

#Preview {
    WelcomeView()
} 