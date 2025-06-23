import SwiftUI

struct FAQView: View {
    @ObservedObject var viewModel = FAQViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.gray.opacity(0.2), radius: 2)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Title
            Text("FAQs")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Text("Popular Questions")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // FAQ List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.items) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation {
                                    viewModel.toggleItem(item)
                                }
                            }) {
                                HStack {
                                    Text(item.question)
                                        .multilineTextAlignment(.leading)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(.degrees(item.isExpanded ? 180 : 0))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                            }
                            
                            if item.isExpanded {
                                Text(item.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            Divider()
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .background(Color(.systemGray6))
        .navigationBarHidden(true)
    }
}
