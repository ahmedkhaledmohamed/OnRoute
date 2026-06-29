import Foundation

final class AnalyticsService {
    static let shared = AnalyticsService()

    let anonymousId: String

    private init() {
        let key = "analyticsAnonymousId"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            anonymousId = existing
        } else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: key)
            anonymousId = id
        }
    }

    func track(_ event: String, properties: [String: Any] = [:]) {
        let body: [String: Any] = [
            "event": event,
            "anonymousId": anonymousId,
            "properties": properties,
        ]

        guard let url = URL(string: "\(APIService.baseURL)/api/event"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        Task {
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
