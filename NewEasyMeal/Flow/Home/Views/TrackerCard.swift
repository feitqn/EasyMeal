import SwiftUI

struct TrackerCard: View {
    let tracker: TrackerInfo
    let burned: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tracker.title)
                .font(AppFonts.subheadline)
                .fontWeight(.medium)
            
            Text("Goal: \(tracker.goal)")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text(tracker.value)
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 5)
            
            if tracker.title.contains("Steps") {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(AppColors.stepsColor)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: geometry.size.width, height: 5)
                                .foregroundColor(AppColors.secondary)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: geometry.size.width * tracker.progress, height: 5)
                                .foregroundColor(AppColors.stepsColor)
                        }
                    }
                    .frame(height: 5)
                }
            } else if tracker.title.contains("Exercise") {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppColors.exerciseColor)
                    Text("\(burned) kcal")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
//                
//                HStack {
//                    Image(systemName: "clock")
//                        .foregroundColor(AppColors.textSecondary)
//                    Text("1 h 30 min")
//                        .font(AppFonts.caption)
//                        .foregroundColor(AppColors.textSecondary)
//                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
