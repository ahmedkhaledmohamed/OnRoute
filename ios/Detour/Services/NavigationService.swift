import UIKit
import MapKit
import CoreLocation

enum NavigationApp: String, CaseIterable, Identifiable {
    case appleMaps = "Apple Maps"
    case googleMaps = "Google Maps"
    case waze = "Waze"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appleMaps: return "map.fill"
        case .googleMaps: return "globe"
        case .waze: return "car.fill"
        }
    }

    var isInstalled: Bool {
        switch self {
        case .appleMaps: return true
        case .googleMaps:
            return UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)
        case .waze:
            return UIApplication.shared.canOpenURL(URL(string: "waze://")!)
        }
    }

    static var available: [NavigationApp] {
        allCases.filter(\.isInstalled)
    }
}

struct NavigationService {
    static func navigate(
        to poi: POIResult,
        from origin: CLLocationCoordinate2D?,
        originName: String?,
        destination: CLLocationCoordinate2D?,
        destinationName: String?,
        using app: NavigationApp
    ) {
        switch app {
        case .appleMaps:
            openAppleMaps(poi: poi, origin: origin, destination: destination)
        case .googleMaps:
            openGoogleMaps(poi: poi, origin: origin, originName: originName, destination: destination, destinationName: destinationName)
        case .waze:
            openWaze(poi: poi)
        }
    }

    static func copyAddress(_ poi: POIResult) {
        UIPasteboard.general.string = poi.address
    }

    private static func openAppleMaps(
        poi: POIResult,
        origin: CLLocationCoordinate2D?,
        destination: CLLocationCoordinate2D?
    ) {
        let poiPlacemark = MKPlacemark(coordinate: poi.coordinate)
        let poiItem = MKMapItem(placemark: poiPlacemark)
        poiItem.name = poi.name

        var items: [MKMapItem] = []

        if let origin {
            let originPlacemark = MKPlacemark(coordinate: origin)
            items.append(MKMapItem(placemark: originPlacemark))
        } else {
            items.append(.forCurrentLocation())
        }

        items.append(poiItem)

        if let destination {
            let destPlacemark = MKPlacemark(coordinate: destination)
            let destItem = MKMapItem(placemark: destPlacemark)
            items.append(destItem)
        }

        MKMapItem.openMaps(
            with: items,
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }

    private static func openGoogleMaps(
        poi: POIResult,
        origin: CLLocationCoordinate2D?,
        originName: String?,
        destination: CLLocationCoordinate2D?,
        destinationName: String?
    ) {
        // Use Google Maps universal link with addresses for readable waypoints
        var components = URLComponents(string: "https://www.google.com/maps/dir/")!

        let originStr = originName?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? (origin.map { "\($0.latitude),\($0.longitude)" } ?? "")
        let poiStr = poi.address.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? poi.name
        let destStr = destinationName?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? (destination.map { "\($0.latitude),\($0.longitude)" } ?? "")

        components.path = "/maps/dir/\(originStr)/\(poiStr)/\(destStr)"

        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }

    private static func openWaze(poi: POIResult) {
        let urlString = "waze://?ll=\(poi.coordinate.latitude),\(poi.coordinate.longitude)&navigate=yes"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
