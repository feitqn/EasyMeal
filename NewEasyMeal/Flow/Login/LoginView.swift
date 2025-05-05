import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    var onButtonTapped: (String, String) -> ()
    var onRegisterTapped: Callback
    @State var isSecured: Bool = true
    @State private var textWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("Welcome back! Glad to see you, Again!")
                .padding(.horizontal, 32)
                .font(.urbanBold(size: 32))
                .foregroundColor(.black)
            VStack() {
                CustomTextField(word: $viewModel.email,
                                placeholder: "Username")
                    .padding(.bottom)
                HStack {
                    Text(viewModel.error)
                                .foregroundColor(.red)
                                .font(.system(size: 13))
                                .frame(alignment: .leading)
                    Spacer()
                }.padding(.leading)
                ZStack(alignment: .trailing) {
                    CustomTextField(word: $viewModel.password, placeholder: "Password", isSecured: isSecured)
                    Button(action: {
                        self.isSecured.toggle()
                    }) {
                        Image(systemName: self.isSecured ? "eye.slash" : "eye")
                            .accentColor(.gray)
                    }.padding(.trailing, 15)
                }
                HStack {
                    Spacer()
                    Button {
                        
                    } label: {
                        Text("Қүпия сөзді ұмыттыңыз ба?")
                            .font(.system(size: 15,weight: .regular))
                            .foregroundColor(.white)
                    }
                    .padding(.top,7)
                    .padding(.trailing, 15)
                }
                
                CustomButtonView(title: "Login") {
                    onButtonTapped(viewModel.email, viewModel.password)
                }
                .frame(width: 300, height: 60)
                .padding(.top, 42)
            }
            .padding(.horizontal,10)
            .padding(.top, 30)
            
            DividerWithText(text: "or Login with")
                .padding(.horizontal, 32)
                .padding(.top, 12)
            
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
            
            
            HStack {
                Text("Don’t have an account? ")
                    .font(.urban(size: 15))
                    .foregroundColor(.black)
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear {
                            self.textWidth = geometry.size.width
                        }
                    })
                Button {
                    onRegisterTapped()
                } label: {
                    
                    Text("Register Now")
                        .font(.urban(size: 15))
                        .foregroundColor(.blue)
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                self.textWidth = geometry.size.width
                            }
                        })
                }
                
            }
            .padding(.top, 133)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CustomTextField: View {
    @Binding var word: String
    var placeholder: String
    var iconName: String = "person.circle"
    var isSecured: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Colors._E8ECF4, lineWidth: 1)
                .background(Colors._F7F8F9)
                .cornerRadius(10)
            
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.gray)
                
                if isSecured {
                    SecureField(placeholder, text: $word)
                        .padding(.vertical, 12)
                } else {
                    TextField(placeholder, text: $word)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 65)
        .frame(maxWidth: 344)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel(),
                  onButtonTapped: {_,_ in},
                  onRegisterTapped: {})
    }
}
