import SwiftUI

struct EmailPromptView: View {
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var submitted = false

    var body: some View {
        VStack(spacing: 12) {
            if submitted {
                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.accentColor)
                    Text("You're on the list!")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.vertical, 16)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }
            } else {
                Text("Get OnRoute updates")
                    .font(.subheadline.weight(.semibold))

                Text("We'll let you know when new features drop.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    TextField("your@email.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Join") {
                        submitEmail()
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!email.contains("@"))
                }

                Button("No thanks") {
                    UserDefaults.standard.set(true, forKey: "hasSeenEmailPrompt")
                    isPresented = false
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }

    private func submitEmail() {
        let body: [String: Any] = [
            "email": email.lowercased().trimmingCharacters(in: .whitespaces),
            "anonymousId": AnalyticsService.shared.anonymousId,
            "platform": "iOS",
        ]

        guard let url = URL(string: "\(APIService.baseURL)/api/subscribe"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        Task { _ = try? await URLSession.shared.data(for: request) }

        UserDefaults.standard.set(true, forKey: "hasSeenEmailPrompt")
        submitted = true
    }
}
