import SwiftUI

struct MealRow: View {
    var title: String
    var current: Int
    var total: Int
    var color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: "fork.knife")
                    .foregroundColor(color)
                )

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)

                ProgressView(value: Float(current), total: Float(total))
                    .accentColor(color)

                Text("\(current)/\(total) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
    }
}
