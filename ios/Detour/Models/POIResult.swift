import Foundation
import CoreLocation

struct POIResult: Identifiable, Codable, Hashable {
    let placeId: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let detourSeconds: Int
    let detourFormatted: String
    let rating: Double
    let userRatingCount: Int
    let isOpenNow: Bool
    let priceLevel: String?
    let phoneNumber: String?
    let todayHours: String?
    let types: [String]
    let photoReference: String?

    var id: String { placeId }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var priceLevelDisplay: String? {
        switch priceLevel {
        case "PRICE_LEVEL_INEXPENSIVE": return "$"
        case "PRICE_LEVEL_MODERATE": return "$$"
        case "PRICE_LEVEL_EXPENSIVE": return "$$$"
        case "PRICE_LEVEL_VERY_EXPENSIVE": return "$$$$"
        default: return nil
        }
    }

    var detourColor: DetourColor {
        let minutes = detourSeconds / 60
        if minutes < 3 { return .green }
        if minutes < 7 { return .yellow }
        if minutes < 15 { return .orange }
        return .red
    }

    enum DetourColor: String {
        case green, yellow, orange, red
    }
}

struct StopResults: Codable {
    let query: String
    let results: [POIResult]
}

struct SearchResponse: Codable {
    let results: [POIResult]
    let stops: [StopResults]?
    let route: RouteInfo
}

struct RouteInfo: Codable {
    let encodedPolyline: String
    let durationSeconds: Int
    let distanceMeters: Int
}
