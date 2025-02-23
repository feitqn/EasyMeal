import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            VStack {
                VStack {
                    Image("splash-logo") // Убедитесь, что добавили изображение в Assets
                        .resizable()
                        .frame(width: 100, height: 100)
                    
                    Text("Diploma")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    print("SplashView animation started") // Добавим для отладки
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 0.9
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                print("SplashView appeared") // Добавим для отладки
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                        print("SplashView transitioning to ContentView") // Добавим для отладки
                    }
                }
            }
        }
    }
} 
