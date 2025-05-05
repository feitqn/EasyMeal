import SwiftUI

// OnboardingView.swift
struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onSucceed: Callback?

    var body: some View {
        VStack {
            Group {
                switch viewModel.step {
                case .goal: GoalSelectionView(viewModel: viewModel)
                case .gender: GenderSelectionView(viewModel: viewModel)
                case .birthday: BirthdaySelectionView(viewModel: viewModel)
                case .height:
                    UnitInputView(title: "Enter your height", value: $viewModel.height, unitType: .height)
                case .currentWeight:
                    UnitInputView(title: "Enter your current weight", value: $viewModel.weight, unitType: .weight)
                case .targetWeight:
                    UnitInputView(title: "Enter your target weight", value: $viewModel.targetWeight, unitType: .weight)
                case .loading: LoadingView()
                case .done: DoneView(onSucceed: {
                    onSucceed?()
                })
                }
            }
            if viewModel.step != .loading && viewModel.step != .done {
                CustomButtonView(title: "Continue", action: {
                    viewModel.next()
                })
                .frame(width: 300, height: 60)
                .padding()
            }
        }
        .animation(.easeInOut, value: viewModel.step)
        .padding()
    }
}

struct GoalSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What is your current goal?")
                .font(.title2)
                .bold()

            ForEach(WeightGoal.allCases) { goal in
                GoalRow(goal: goal, isSelected: viewModel.selectedGoal == goal)
                    .onTapGesture {
                        viewModel.selectedGoal = goal
                    }
            }
        }
    }
}

struct GoalRow: View {
    let goal: WeightGoal
    let isSelected: Bool

    var body: some View {
        HStack {
            HStack(spacing: 16) {
                goal.image
                    .resizable()
                    .frame(width: 30, height: 30)
                Text(goal.rawValue)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(.green)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.green : Color.gray))
    }
}

// GenderSelectionView.swift
struct GenderSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Select your gender")
                .font(.title2)
                .bold()
            ForEach(Gender.allCases) { gender in
                HStack {
                    HStack(spacing: 16) {
                        gender.image
                            .resizable()
                            .frame(width: 30, height: 40, alignment: .leading)
                        Text(gender.rawValue)
                    }
                    Spacer()
                    Image(systemName: viewModel.selectedGender == gender ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.green)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).stroke(viewModel.selectedGender == gender ? Color.green : Color.gray))
                .onTapGesture {
                    viewModel.selectedGender = gender
                }
            }
        }
    }
}

// BirthdaySelectionView.swift
struct BirthdaySelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Select your birthday")
                .font(.title2)
                .bold()
            DatePicker("", selection: $viewModel.birthdate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
    }
}

// HeightSelectionView.swift

enum InputUnit: String {
    case cm, ft_in
    case kg, lbs

    var display: String {
        switch self {
        case .cm: return "cm"
        case .ft_in: return "ft/in"
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
}

struct UnitInputView: View {
    var title: String
    @Binding var value: Double
    var unitType: UnitType

    @State private var selectedUnit: InputUnit

    init(title: String, value: Binding<Double>, unitType: UnitType) {
        self.title = title
        self._value = value
        self.unitType = unitType
        self._selectedUnit = State(initialValue: unitType.defaultUnit)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.title2)
                .bold()

            HStack {
                Spacer()
                TextField("0", value: $value, formatter: NumberFormatter.decimalFormatter)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                Spacer()
            }

            HStack(spacing: 16) {
                ForEach(unitType.units, id: \.self) { unit in
                    Button(action: {
                        selectedUnit = unit
                        value = unitType.convert(value: value, from: selectedUnit, to: unit)
                    }) {
                        Text(unit.display)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(unit == selectedUnit ? Color.green.opacity(0.2) : Color.clear)
                            )
                    }
                    .foregroundColor(unit == selectedUnit ? .green : .gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(unit == selectedUnit ? Color.green : Color.gray.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
    }
}


// WeightInputView.swift
struct WeightInputView: View {
    var title: String
    @Binding var weight: Double

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.title2)
                .bold()
            Stepper(value: $weight, in: 30...300, step: 0.5) {
                Text("\(weight, specifier: "%.1f") kg")
            }
        }
    }
}

struct LoadingView: View {
    @State private var progress: CGFloat = 0.0
    let duration: TimeInterval = 5

    var body: some View {
        VStack(spacing: 24) {
            Text("Preparing your plan...")
                .font(.title2)
                .bold()

            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 6)
                    .foregroundColor(Color.gray.opacity(0.3))

                Capsule()
                    .frame(width: progress, height: 6)
                    .foregroundColor(.green)
            }
            .frame(height: 6)
            .padding(.horizontal)
            .onAppear {
                withAnimation(.linear(duration: duration)) {
                    progress = UIScreen.main.bounds.width - 32
                }
            }

            Text("Just a moment...")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// DoneView.swift
struct DoneView: View {
    var onSucceed: (() ->())?
    
    var body: some View {
        VStack(spacing: 16) {
            Image("party")
                .resizable()
                .frame(width: 130, height: 130)
                .foregroundColor(.green)
            Text("Your plan is ready!")
                .font(.title)
                .bold()
            Text("Work towards your goal and enjoy every meal along the way.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            CustomButtonView(title: "Continue", action: {
                onSucceed?()
            })
            .frame(width: 300, height: 60)
        }
        .padding()
    }
}

enum UnitType {
    case height
    case weight

    var units: [InputUnit] {
        switch self {
        case .height: return [.cm, .ft_in]
        case .weight: return [.kg, .lbs]
        }
    }

    var defaultUnit: InputUnit {
        switch self {
        case .height: return .cm
        case .weight: return .kg
        }
    }

    func convert(value: Double, from: InputUnit, to: InputUnit) -> Double {
        switch (from, to) {
        case (.cm, .ft_in):
            return value / 30.48
        case (.ft_in, .cm):
            return value * 30.48
        case (.kg, .lbs):
            return value * 2.20462
        case (.lbs, .kg):
            return value / 2.20462
        default:
            return value
        }
    }
}

extension NumberFormatter {
    static var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
}
