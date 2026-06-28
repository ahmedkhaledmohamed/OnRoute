import SwiftUI

struct NPSPromptView: View {
    @Binding var isPresented: Bool
    @State private var selectedScore: Int?
    @State private var comment = ""
    @State private var submitted = false

    var body: some View {
        VStack(spacing: 16) {
            if submitted {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    Text("Thanks for your feedback!")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.vertical, 20)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }
            } else {
                Text("How likely are you to recommend OnRoute?")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 6) {
                    ForEach(0...10, id: \.self) { score in
                        Button {
                            selectedScore = score
                        } label: {
                            Text("\(score)")
                                .font(.caption2.weight(.medium))
                                .frame(width: 26, height: 26)
                                .background(
                                    selectedScore == score
                                        ? Color.accentColor
                                        : Color(.systemGray5),
                                    in: Circle()
                                )
                                .foregroundStyle(selectedScore == score ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    Text("Not likely")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Very likely")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                TextField("Any other feedback? (optional)", text: $comment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .lineLimit(3)

                HStack {
                    Button("Not now") {
                        isPresented = false
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("Submit") {
                        guard let score = selectedScore else { return }
                        submitFeedback(score: score, comment: comment)
                        submitted = true
                    }
                    .font(.caption.weight(.semibold))
                    .disabled(selectedScore == nil)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }

    private func submitFeedback(score: Int, comment: String) {
        let body: [String: Any] = [
            "anonymousId": AnalyticsService.shared.anonymousId,
            "score": score,
            "comment": comment,
            "platform": "iOS",
        ]

        guard let url = URL(string: "\(APIService.baseURL)/api/feedback"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        Task { _ = try? await URLSession.shared.data(for: request) }

        UserDefaults.standard.set(true, forKey: "hasSubmittedNPS")
    }
}
