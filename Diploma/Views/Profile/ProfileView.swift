import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authService: AuthService
    @FetchRequest(
        entity: CDUser.entity(),
        sortDescriptors: [],
        animation: .default
    ) private var users: FetchedResults<CDUser>
    
    @State private var showEditGoal = false
    @State private var showEditBirthday = false
    @State private var showEditGender = false
    @State private var showEditHeight = false
    @State private var showEditCurrentWeight = false
    @State private var showEditTargetWeight = false
    @State private var showLogoutAlert = false
    @State private var showingFAQ = false
    @State private var showingHelp = false
    @State private var showDeleteAccountAlert = false
    
    private var user: CDUser? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Логотип
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    // Аватар и имя пользователя
                    VStack(spacing: 8) {
                        Image("avatar-placeholder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        
                        if let user = user {
                            Text(user.username ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(user.email ?? "No email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Мои данные
                    VStack(alignment: .leading, spacing: 16) {
                        Text("My data")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            if let user = user {
                                // Цель
                                Button {
                                    showEditGoal = true
                                } label: {
                                    ProfileDataRow(
                                        title: "Goal",
                                        value: user.goal.rawValue,
                                        showDivider: true
                                    )
                                }
                                
                                // День рождения
                                Button {
                                    showEditBirthday = true
                                } label: {
                                    ProfileDataRow(
                                        title: "Birthday",
                                        value: formatDate(user.birthday),
                                        showDivider: true
                                    )
                                }
                                
                                // Пол
                                Button {
                                    showEditGender = true
                                } label: {
                                    ProfileDataRow(
                                        title: "Gender",
                                        value: user.gender?.isEmpty ?? true ? "Not set" : user.gender ?? "",
                                        showDivider: true
                                    )
                                }
                                
                                // Рост
                                Button {
                                    showEditHeight = true
                                } label: {
                                    ProfileDataRow(
                                        title: "Height",
                                        value: "\(Int(user.height)) cm",
                                        showDivider: true
                                    )
                                }
                                
                                // Текущий вес
                                Button {
                                    showEditCurrentWeight = true
                                } label: {
                                    ProfileDataRow(
                                        title: "Current weight",
                                        value: "\(Int(user.currentWeight)) kg",
                                        showDivider: true
                                    )
                                }
                                
                                // Целевой вес
                                Button {
                                    showEditTargetWeight = true
                                } label: {
                                    ProfileDataRow(
                                        title: "Target weight",
                                        value: "\(Int(user.targetWeight)) kg",
                                        showDivider: false
                                    )
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    // Настройки
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: NotificationsSettingsView()) {
                                SettingsRow(
                                    title: "Notifications",
                                    icon: "bell",
                                    showDivider: true
                                )
                            }
                            
                            // Временно закомментировано
                            /*
                            NavigationLink(destination: FAQView()) {
                                SettingsRow(
                                    title: "FAQ",
                                    icon: "questionmark.circle",
                                    showDivider: true
                                )
                            }
                            
                            NavigationLink(destination: HelpView()) {
                                SettingsRow(
                                    title: "Help",
                                    icon: "info.circle",
                                    showDivider: false
                                )
                            }
                            */
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    // Кнопка выхода
                    Button {
                        showLogoutAlert = true
                    } label: {
                        Text("Выйти")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                    
                    // Кнопка удаления аккаунта
                    Button {
                        showDeleteAccountAlert = true
                    } label: {
                        Text("Удалить аккаунт")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditGoal) {
                EditGoalView(goal: user?.goal ?? .maintenance)
            }
            .sheet(isPresented: $showEditBirthday) {
                EditBirthdayView(birthday: user?.birthday ?? Date())
            }
            .sheet(isPresented: $showEditGender) {
                EditGenderView(gender: user?.gender ?? "")
            }
            .sheet(isPresented: $showEditHeight) {
                EditHeightView(height: user?.height ?? 170)
            }
            .sheet(isPresented: $showEditCurrentWeight) {
                EditWeightView(
                    weight: user?.currentWeight ?? 70,
                    title: "Change current weight"
                )
            }
            .sheet(isPresented: $showEditTargetWeight) {
                EditWeightView(
                    weight: user?.targetWeight ?? 70,
                    title: "Change target weight"
                )
            }
            
            // Временно закомментировано
            /*
            .sheet(isPresented: $showingFAQ) {
                FAQView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            */
            
            .alert("Выход", isPresented: $showLogoutAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Выйти", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Вы уверены, что хотите выйти?")
            }
            
            .alert("Удаление аккаунта", isPresented: $showDeleteAccountAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    Task {
                        try? await authService.deleteCurrentUser()
                    }
                }
            } message: {
                Text("Вы уверены, что хотите удалить свой аккаунт? Это действие нельзя отменить.")
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

struct ProfileDataRow: View {
    let title: String
    let value: String
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Text(value)
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
            
            if showDivider {
                Divider()
                    .padding(.horizontal)
            }
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
            
            if showDivider {
                Divider()
                    .padding(.horizontal)
            }
        }
    }
}

struct FAQView: View {
    var body: some View {
        Text("FAQ")
            .navigationTitle("FAQ")
    }
}

struct HelpView: View {
    var body: some View {
        Text("Help")
            .navigationTitle("Help")
    }
} 
