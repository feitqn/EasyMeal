import SwiftUI
import CoreData

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    
    @State private var selectedGoal: Goal
    
    init(goal: Goal) {
        _selectedGoal = State(initialValue: goal)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Change your goal?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Picker("Goal", selection: $selectedGoal) {
                    ForEach(Goal.allCases, id: \.self) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }
                .pickerStyle(.wheel)
                
                Button {
                    if let user = users.first {
                        user.goal = selectedGoal
                        try? viewContext.save()
                    }
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct EditGenderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    
    @State private var selectedGender: String
    private let genders = ["Male", "Female", "Other"]
    
    init(gender: String) {
        _selectedGender = State(initialValue: gender)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Change gender?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Picker("Gender", selection: $selectedGender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender).tag(gender)
                    }
                }
                .pickerStyle(.wheel)
                
                Button {
                    if let user = users.first {
                        user.gender = selectedGender
                        try? viewContext.save()
                    }
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct EditHeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    
    @State private var height: Double
    
    init(height: Double) {
        _height = State(initialValue: height)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Change your height?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Picker("Height", selection: $height) {
                    ForEach(120...220, id: \.self) { cm in
                        Text("\(cm) cm").tag(Double(cm))
                    }
                }
                .pickerStyle(.wheel)
                
                Button {
                    if let user = users.first {
                        user.height = height
                        try? viewContext.save()
                    }
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct EditBirthdayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    
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

struct EditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    
    @State private var weight: Double
    let title: String
    
    init(weight: Double, title: String) {
        _weight = State(initialValue: weight)
        self.title = title
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Picker("Weight", selection: $weight) {
                    ForEach(30...200, id: \.self) { kg in
                        Text("\(kg) kg").tag(Double(kg))
                    }
                }
                .pickerStyle(.wheel)
                
                Button {
                    if let user = users.first {
                        if title.contains("current") {
                            user.currentWeight = weight
                        } else {
                            user.targetWeight = weight
                        }
                        try? viewContext.save()
                    }
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
} 