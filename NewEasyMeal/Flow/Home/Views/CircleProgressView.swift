import SwiftUI

struct CircleProgressView: View {
    var progress: CGFloat  // 0.0 to 1.0
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)

            Text(label)
                .font(.title2)
                .bold()
                .foregroundColor(.green)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120, height: 120)
    }
}

