import SwiftUI

struct ExerciseRowView: View {
    let exercise: CDExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text("\(exercise.sets) подхода × \(exercise.reps) повторений")
                .font(.subheadline)
                .foregroundColor(.gray)
            if let description = exercise.exerciseDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
} 