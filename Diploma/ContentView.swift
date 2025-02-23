import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    
    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
            } else {
                WelcomeView()
                    .environmentObject(authService)
            }
        }
    }
}

#Preview {
    ContentView()
}
