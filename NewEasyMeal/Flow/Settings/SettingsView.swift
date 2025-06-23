import SwiftUI

struct SettingsView: View {
    // Callback для навигации в UIViewController
    var onNavigateBack: (() -> Void)?
    var onUnitsSelected: (() -> Void)?
    var onNotificationsSelected: (() -> Void)?
    var onPrivacySecuritySelected: (() -> Void)?
    var onHealthPlatformSelected: ((HealthPlatform) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header с кнопкой назад
            HStack {
                Button(action: {
                    onNavigateBack?()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Заголовок
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Основные настройки
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Units",
                    action: {
                        onUnitsSelected?()
                    }
                )
                
                Divider()
                    .padding(.leading, 20)
                
                SettingsRow(
                    title: "Notifications",
                    action: {
                        onNotificationsSelected?()
                    }
                )
                
                Divider()
                    .padding(.leading, 20)
                
                SettingsRow(
                    title: "Privacy & Security",
                    action: {
                        onPrivacySecuritySelected?()
                    }
                )
            }
            .padding(.top, 40)
            
            // Секция синхронизации с платформами здоровья
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Sync with Health Platforms")
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                }
                
                // Иконки платформ здоровья
                HStack(spacing: 15) {
                    HealthPlatformIcon(
                        platform: .heart,
                        backgroundColor: .pink,
                        iconColor: .white
                    ) {
                        onHealthPlatformSelected?(.heart)
                    }
                    
                    HealthPlatformIcon(
                        platform: .activity,
                        backgroundColor: .black,
                        iconColor: .green
                    ) {
                        onHealthPlatformSelected?(.activity)
                    }
                    
                    HealthPlatformIcon(
                        platform: .fitbit,
                        backgroundColor: Color(red: 0.3, green: 0.7, blue: 0.7),
                        iconColor: .white
                    ) {
                        onHealthPlatformSelected?(.fitbit)
                    }
                    
                    HealthPlatformIcon(
                        platform: .samsung,
                        backgroundColor: Color(red: 0.2, green: 0.4, blue: 0.6),
                        iconColor: .white
                    ) {
                        onHealthPlatformSelected?(.samsung)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct SettingsRow: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
}

struct HealthPlatformIcon: View {
    let platform: HealthPlatform
    let backgroundColor: Color
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: platform.iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }
        }
    }
}

enum HealthPlatform {
    case heart
    case activity
    case fitbit
    case samsung
    
    var iconName: String {
        switch self {
        case .heart:
            return "heart.fill"
        case .activity:
            return "circle.dotted"
        case .fitbit:
            return "square.grid.3x3.fill"
        case .samsung:
            return "arrow.clockwise"
        }
    }
}
