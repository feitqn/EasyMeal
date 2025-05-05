import SwiftUI

struct SettingView: View {
    var onTapLogout: Callback
    var onTapEdit: Callback
    var onTapBack: Callback
    var body: some View {
        VStack {
            HStack {
                Button {
                    onTapBack()
                } label: {
                    Image("chevronLeft")
                        .frame(width: 29, height: 29)
        
                }
                Spacer()
                Text("Баптау")
                    .foregroundColor(.black)
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 13)
            .padding(.horizontal, 5)
            VStack(spacing: 16) {
                Button {
                    onTapEdit()
                } label: {
                    HStack(spacing: 11) {
                        Image("pencil")
                        Text("Өңдеу")
                        Spacer()
                    }.padding(.leading, 15)
                }

//                Button {
//                    
//                } label: {
//                    HStack(spacing: 11) {
//                        Image("internet")
//                        Text("Язык")
//                        Spacer()
//                    }.padding(.leading, 15)
//                }.buttonStyle(BlueButton())
                
                Button {
                    onTapLogout()
                } label: {
                    HStack(spacing: 11) {
                        Image("exit")
                        Text("Шығу")
                        Spacer()
                    }.padding(.leading, 15)
                }
            }.padding(.top, 84)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Colors.backColor)
    }
}

#Preview {
    SettingView(onTapLogout: {}, onTapEdit: {}, onTapBack: {})
}
