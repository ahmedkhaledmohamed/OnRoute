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
    #if DEBUG
    static let baseURL = "http://localhost:3000"
    #else
    static let baseURL = "https://detour-backend.vercel.app"
    #endif

    static func search(
        origin: (lat: Double, lng: Double),
        destination: (lat: Double, lng: Double),
        query: String,
        maxDetourMinutes: Int? = nil,
        openNow: Bool = true
    ) async throws -> SearchResponse {
        guard let url = URL(string: "\(baseURL)/api/search") else {
            throw APIError.invalidURL
        }

        var body: [String: Any] = [
            "origin": ["lat": origin.lat, "lng": origin.lng],
            "destination": ["lat": destination.lat, "lng": destination.lng],
            "query": query,
            "openNow": openNow,
        ]

        if let maxDetour = maxDetourMinutes {
            body["maxDetourMinutes"] = maxDetour
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
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
}
