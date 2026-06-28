import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .networkError(let error): return error.localizedDescription
        case .serverError(let message): return message
        case .decodingError: return "Unexpected response format"
        }
    }
}

struct APIService {
    static let baseURL = "https://backend-navy-iota.vercel.app"

    static func search(
        origin: (lat: Double, lng: Double),
        destination: (lat: Double, lng: Double),
        query: String,
        maxDetourMinutes: Int? = nil,
        openNow: Bool = true,
        travelMode: String = "DRIVE"
    ) async throws -> SearchResponse {
        guard let url = URL(string: "\(baseURL)/api/search") else {
            throw APIError.invalidURL
        }

        var body: [String: Any] = [
            "origin": ["lat": origin.lat, "lng": origin.lng],
            "destination": ["lat": destination.lat, "lng": destination.lng],
            "query": query,
            "openNow": openNow,
            "travelMode": travelMode,
        ]

        if let maxDetour = maxDetourMinutes {
            body["maxDetourMinutes"] = maxDetour
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AnalyticsService.shared.anonymousId, forHTTPHeaderField: "X-Anonymous-Id")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        var lastError: Error = APIError.serverError("Unknown error")

        for attempt in 0..<2 {
            if attempt > 0 {
                try await Task.sleep(for: .seconds(1))
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response")
            }

            if httpResponse.statusCode >= 500 || httpResponse.statusCode == 429 {
                lastError = APIError.serverError("Server error (\(httpResponse.statusCode))")
                continue
            }

            if httpResponse.statusCode != 200 {
                if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorBody["error"] {
                    throw APIError.serverError(message)
                }
                throw APIError.serverError("Server error (\(httpResponse.statusCode))")
            }

            do {
                return try JSONDecoder().decode(SearchResponse.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        }

        throw lastError
    }
}
