import SwiftUI
import UIKit

struct PersonalInfoView: View {
    var onTapExit: (() -> Void)?

    @ObservedObject var viewModel: PersonalInfoViewModel

    @State private var showGenderPicker = false
    @State private var showDatePicker = false
    @State private var profileImage: Image? = nil
    @State private var isPresentingImagePicker = false
    @State private var isImageSourceSheetPresented = false
    @State private var isCamera = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    onTapExit?()
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.gray.opacity(0.2), radius: 2)
                }

                Spacer()

                Button(action: {
                    viewModel.saveChanges {
                        onTapExit?()
                    }
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
            Button(action: {
                isImageSourceSheetPresented = true
            }) {
                ZStack {
                    if let image = profileImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.black)
                            )
                    }

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
            .actionSheet(isPresented: $isImageSourceSheetPresented) {
                ActionSheet(title: Text("Select Image Source"), buttons: [
                    .default(Text("Camera")) {
                        isCamera = true
                        isPresentingImagePicker = true
                    },
                    .default(Text("Photo Library")) {
                        isCamera = false
                        isPresentingImagePicker = true
                    },
                    .cancel()
                ])
            }
            .sheet(isPresented: $isPresentingImagePicker) {
                ImagePicker(sourceType: isCamera ? .camera : .photoLibrary) { uiImage in
                    profileImage = Image(uiImage: uiImage)
                    saveImageToDisk(image: uiImage)
                }
            }
            .onAppear {
                loadImageFromDisk()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)

            // Form Fields
            VStack(spacing: 25) {
                formField(title: "Username", value: $viewModel.username, icon: "person.fill")
                formField(title: "E-mail", value: $viewModel.email, icon: "envelope.fill")
                    .disabled(true)

                pickerField(title: "Gender", value: $viewModel.gender, icon: "person.2.fill") {
                    showGenderPicker = true
                }

                pickerField(title: "Birthday", value: .constant($viewModel.birthDate.mapToString().wrappedValue), icon: "birthday.cake.fill") {
                    showDatePicker = true
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 16)
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showGenderPicker) {
            VStack {
                Text("Select Gender")
                    .font(.headline)
                    .padding()

                Picker("Gender", selection: $viewModel.gender) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                }
                .pickerStyle(.wheel)
                .labelsHidden()

                Button("Done") {
                    showGenderPicker = false
                }
                .padding()
            }
            .presentationDetents([.fraction(0.3)])
        }
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("Select your birthday", selection: $viewModel.birthDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()

                Button("Done") {
                    showDatePicker = false
                }
                .padding(.bottom, 32)
            }
            .presentationDetents([.fraction(0.5)])
        }
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

    func pickerField(title: String, value: Binding<String>, icon: String, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Button(action: onTap) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 20)

                    Text(value.wrappedValue.isEmpty ? "Select" : value.wrappedValue)
                        .font(.system(size: 16))
                        .foregroundColor(value.wrappedValue.isEmpty ? .gray : .black)

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

    private func saveImageToDisk(image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let url = avatarFileURL()
            try? data.write(to: url)
            UserDefaults.standard.set(url.path, forKey: "avatarPath")
        }
    }

    private func loadImageFromDisk() {
        if let path = UserDefaults.standard.string(forKey: "avatarPath"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let uiImage = UIImage(data: data) {
            profileImage = Image(uiImage: uiImage)
        }
    }

    private func avatarFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar.jpg")
    }
}
