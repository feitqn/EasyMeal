import SwiftUI

struct MacroView: View {
    var name: String
    var value: Int

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)

            ProgressView(value: Float(value), total: 100)
                .accentColor(colorForMacro(name))
                .frame(height: 6)

            Text("\(value)g left")
                .font(.caption)
                .frame(width: 60, alignment: .trailing)
        }
    }

    private func colorForMacro(_ name: String) -> Color {
        switch name {
        case "Carbs": return .blue
        case "Protein": return .orange
        case "Fat": return .pink
        default: return .gray
        }
    }
}

