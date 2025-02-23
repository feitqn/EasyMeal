import SwiftUI
import CoreData

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: CDUser.entity(), sortDescriptors: []) private var users: FetchedResults<CDUser>
    
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
                        user.goalRawValue = selectedGoal.rawValue
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
    @FetchRequest(entity: CDUser.entity(), sortDescriptors: []) private var users: FetchedResults<CDUser>
    
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
    @FetchRequest(entity: CDUser.entity(), sortDescriptors: []) private var users: FetchedResults<CDUser>
    
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

struct EditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: CDUser.entity(), sortDescriptors: []) private var users: FetchedResults<CDUser>
    
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