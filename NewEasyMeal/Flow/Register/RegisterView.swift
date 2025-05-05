import SwiftUI

struct RegisterView: View {
    @State var isSecured: Bool = true
    @ObservedObject var viewModel: RegisterViewModel
    var action: Callback
    var completion: Callback
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button {
                    action()
                } label: {
                    Image("chevronLeft")
                        .tint(.black)
                }
                .padding(.leading,9)
                Spacer()
            }
            Spacer()
            Text("Hello! Register to get started!")
                .foregroundColor(Colors.labelColor)
                .font(.urbanBold(size: 32))

            VStack(spacing: 7) {
                CustomTextField(word: $viewModel.name, placeholder: "Аты")
                    .padding(.bottom)
                CustomTextField(word: $viewModel.email, placeholder: "Email")
                    .padding(.bottom)
                ZStack(alignment: .trailing) {
                    CustomTextField(word: $viewModel.password, placeholder: "Құпия сөз", isSecured: isSecured)
                    Button(action: {
                        self.isSecured.toggle()
                    }) {
                        Image(systemName: self.isSecured ? "eye.slash" : "eye")
                            .accentColor(.gray)
                    }.padding(.trailing, 15)
                }
                .padding(.bottom)
            }.padding(.top, 32)
            
            CustomButtonView(title: "Register") {
                viewModel.register(callback: {
                    completion()
                })
            }
            .frame(width: 300, height: 60)
            .padding(.top, 20)
            
            HStack {
                if viewModel.errorMessage != "" {
                    Text(viewModel.errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                    Spacer()
                }
            }
            .padding(.top,25)
            .padding(.horizontal, 30)
            .padding(.bottom)
            
            DividerWithText(text: "or Register with")
                .padding(.horizontal, 32)
            
            HStack(spacing: 16) {
                IconButton(imageName: "facebook") {
                    print("Home tapped")
                }
                IconButton(imageName: "google") {
                    print("Heart tapped")
                }
                IconButton(imageName: "apple") {
                    print("Settings tapped")
                }
            }.padding(.top, 12)
            
            Spacer()

            HStack {
                Text("Already have an account?")
                    .font(.urban(size: 15))
                    .foregroundColor(.black)
                Button {
                    action()
                } label: {
                    Text("Login Now")
                        .font(.urban(size: 15))
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(viewModel: RegisterViewModel(), action: {}, completion: {})
    }
}

struct DividerWithText: View {
    var text: String
    
    var body: some View {
        HStack {
            line
            Text(text)
                .font(.urban(size: 14)) // или любой твой шрифт
                .foregroundColor(.gray)
            line
        }
    }
    
    private var line: some View {
        VStack { Divider().background(Color.gray) }
    }
}

struct IconButton: View {
    var imageName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.white)
                .frame(width: 85, height: 55)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Colors._E8ECF4, lineWidth: 1)
                )
        }
    }
}
