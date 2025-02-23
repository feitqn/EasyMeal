import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                }
                .tag(0)
            
            RecipesView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "fork.knife.circle.fill" : "fork.knife.circle")
                        Text("Recipes")
                    }
                }
                .tag(1)
            
            ProgressView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 2 ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                        Text("Progress")
                    }
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                        Text("Profile")
                    }
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Карточка с дневной статистикой калорий
                    DailyCalorieCard()
                    
                    // Секция приемов пищи
                    MealSection()
                }
                .padding()
            }
            .navigationTitle("Daily Summary")
        }
    }
}

struct DailyCalorieCard: View {
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "leaf")
                    .foregroundColor(.green)
                Text("Daily Calorie Summary")
                    .font(.headline)
                Spacer()
            }
            
            // Круговой прогресс
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.green, lineWidth: 10)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("1243")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("kcal left")
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 150)
            
            // Статистика
            HStack(spacing: 20) {
                StatItem(title: "Eaten", value: "953", unit: "kcal", color: .green)
                StatItem(title: "Burned", value: "100", unit: "kcal", color: .orange)
            }
            
            // Макронутриенты
            HStack(spacing: 20) {
                NutrientBar(title: "Carbs", value: "132g", progress: 0.7, color: .blue)
                NutrientBar(title: "Protein", value: "45g", progress: 0.5, color: .red)
                NutrientBar(title: "Fat", value: "50g", progress: 0.3, color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.gray)
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NutrientBar: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
    }
}

struct MealSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Meals")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(["Breakfast", "Lunch", "Snack", "Dinner"], id: \.self) { meal in
                MealRow(title: meal)
            }
        }
    }
}

struct MealRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Image("meal_placeholder") // Добавьте соответствующие изображения
                .resizable()
                .frame(width: 50, height: 50)
                .cornerRadius(25)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text("653/653 kcal")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
} 