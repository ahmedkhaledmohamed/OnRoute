import Foundation
import SwiftUI

@Observable
final class AnalyticsService {
    static let shared = AnalyticsService()

    @AppStorage("analyticsAnonymousId") private var storedId = ""

    var anonymousId: String {
        if storedId.isEmpty {
            storedId = UUID().uuidString
        }
        return storedId
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
