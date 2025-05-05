import SwiftUI

// MARK: - Personal Info View
struct PersonalInfoView: View {
    @State private var username = "Aiganym"
    @State private var email = "aiganym@gmail.com"
    @State private var gender = "Female"
    @State private var birthday = "15.04.1982"
    @State private var showBackButton = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    // Back button action
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.gray.opacity(0.2), radius: 2)
                }
                
                Spacer()
                
                Button(action: {
                    // Confirm button action
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            // Title
            Text("Personal Info")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Profile Image
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.black)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                        )
                        .offset(x: 35, y: 35)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
            
            // Form Fields
            VStack(spacing: 25) {
                formField(title: "Username", value: $username, icon: "person.fill")
                formField(title: "E-mail", value: $email, icon: "envelope.fill")
                pickerField(title: "Gender", value: $gender, icon: "person.2.fill")
                formField(title: "Birthday", value: $birthday, icon: "birthday.cake.fill")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 16)
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    func formField(title: String, value: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField("", text: value)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
    
    func pickerField(title: String, value: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                Text(value.wrappedValue)
                    .font(.system(size: 16))
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
}
