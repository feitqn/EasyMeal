import SwiftUI
import CoreData

struct EditBirthdayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authService: AuthService
    @FetchRequest(entity: CDUser.entity(), sortDescriptors: []) private var users: FetchedResults<CDUser>
    
    @State private var birthday: Date
    @State private var showError = false
    
    // Минимальный возраст - 12 лет
    private let minimumAge = 12
    private var maximumDate: Date {
        Calendar.current.date(byAdding: .year, value: -minimumAge, to: Date()) ?? Date()
    }
    
    init(birthday: Date) {
        let defaultDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        _birthday = State(initialValue: birthday == Date() ? defaultDate : birthday)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Birthday",
                    selection: $birthday,
                    in: ...maximumDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Text("Минимальный возраст - \(minimumAge) лет")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            .navigationTitle("Edit Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBirthday()
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Минимальный возраст должен быть \(minimumAge) лет")
            }
        }
    }
    
    private func saveBirthday() {
        // Проверяем возраст
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        guard let age = ageComponents.year, age >= minimumAge else {
            showError = true
            return
        }
        
        if let user = users.first {
            user.birthday = birthday
            user.age = Int16(age)
            
            // Сохраняем изменения
            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Error saving birthday: \(error)")
            }
        }
    }
} 