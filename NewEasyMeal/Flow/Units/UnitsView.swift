//
//  UnitsView.swift
//  NewEasyMeal
//
//  Created by Али Айболатов on 27.05.2025.
//

import SwiftUI

struct UnitsView: View {
    var onTapExit: () -> Void
    @State private var weightUnit = "kg"
    @State private var heightUnit = "cm"
    @State private var energyUnit = "kcal"

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Button(action: {
                    onTapExit()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .padding()
                }
                Spacer()
            }

            Text("Units")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)

            VStack(spacing: 16) {
                UnitToggleRow(title: "Weight", left: "kg", right: "lbs", selected: $weightUnit)
                UnitToggleRow(title: "Height", left: "cm", right: "ft/in", selected: $heightUnit)
                UnitToggleRow(title: "Energy", left: "kcal", right: "kJ", selected: $energyUnit)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()
        }
    }
}

struct UnitToggleRow: View {
    let title: String
    let left: String
    let right: String
    @Binding var selected: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 8) {
                ForEach([left, right], id: \.self) { unit in
                    Button(action: {
                        selected = unit
                    }) {
                        Text(unit)
                            .fontWeight(.medium)
                            .foregroundColor(selected == unit ? .white : .gray)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                            .background(selected == unit ? Color.gray : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}
