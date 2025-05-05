import SwiftUI
//import Kingfisher

// MARK: - Profile View
struct ProfileView: View {
    
    // MARK: - Data
    @ObservedObject var viewModel: ProfileViewModel
    var profileItems: [ProfileOption]
    var servicesItems: [ProfileOption]
    var supportItems: [ProfileOption]
    var navigation: ProfileNavigation
    
    var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    optionSection(title: "", items: profileItems)
                    optionSection(title: "", items: servicesItems)
                    optionSection(title: "", items: supportItems)
                    logoutSection
                }
                .padding()
            }
            .navigationBarTitle("Profile", displayMode: .large)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "pencil")
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 3))

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.user?.name ?? "")
                    .font(.title2).bold()
                Text("viewModel.user.email")
                    .font(.subheadline).foregroundColor(.gray)

                HStack(spacing: 12) {
                    Label(viewModel.user?.currentGoal ?? "", systemImage: "arrow.up.right")
                        .labelStyle(IconOnlyLabelStyle())
                        .foregroundColor(.green)
                    Text("\(viewModel.user?.currentGoal?.capitalized ?? "")")
                        .font(.subheadline)

                    Label("", systemImage: "scalemass")
                        .labelStyle(TitleOnlyLabelStyle())
                    Text(String(format: "%.1f kg", viewModel.user?.weight ?? ""))
                        .font(.subheadline)

                    Label("", systemImage: "flame")
                        .labelStyle(TitleOnlyLabelStyle())
                    Text("\(viewModel.user?.name) kcal")
                        .font(.subheadline)
                }
            }
            Spacer()
        }
    }

    // MARK: - Options Sections
    private func optionSection(title: String, items: [ProfileOption]) -> some View {
        VStack(spacing: 1) {
            ForEach(items) { item in
                Button {
                    navigation.onTapAction(item.action)
                } label: {
                    HStack {
                        Image(systemName: item.icon)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.green)
                        Text(item.title)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
        }
        .cornerRadius(12)
    }

    private var logoutSection: some View {
        Button(action: navigation.onLogout) {
            HStack {
                Image(systemName: "arrow.backward.square")
                    .foregroundColor(.red)
                Text("Log Out")
                    .foregroundColor(.red)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Profile Option Model
struct ProfileOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let action: ProfileAction
}
