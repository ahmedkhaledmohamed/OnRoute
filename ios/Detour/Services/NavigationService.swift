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
        travelMode: String = "DRIVE",
        using app: NavigationApp
    ) {
        AnalyticsService.shared.track("navigation_opened", properties: ["app": app.rawValue])

        switch app {
        case .appleMaps:
            openAppleMaps(poi: poi, origin: origin, destination: destination, travelMode: travelMode)
        case .googleMaps:
            openGoogleMaps(poi: poi, origin: origin, originName: originName, destination: destination, destinationName: destinationName, travelMode: travelMode)
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
        destination: CLLocationCoordinate2D?,
        travelMode: String = "DRIVE"
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
            launchOptions: [MKLaunchOptionsDirectionsModeKey: travelMode == "WALK" ? MKLaunchOptionsDirectionsModeWalking : MKLaunchOptionsDirectionsModeDriving]
        )
    }

    private static func openGoogleMaps(
        poi: POIResult,
        origin: CLLocationCoordinate2D?,
        originName: String?,
        destination: CLLocationCoordinate2D?,
        destinationName: String?,
        travelMode: String = "DRIVE"
    ) {
        let originStr = originName ?? (origin.map { "\($0.latitude),\($0.longitude)" } ?? "")
        let poiStr = poi.address.isEmpty ? "\(poi.coordinate.latitude),\(poi.coordinate.longitude)" : poi.address
        let destStr = destinationName ?? (destination.map { "\($0.latitude),\($0.longitude)" } ?? "")

        let gmapMode: String
        switch travelMode {
        case "WALK": gmapMode = "walking"
        case "BICYCLE": gmapMode = "bicycling"
        default: gmapMode = "driving"
        }

        let urlString = "https://www.google.com/maps/dir/?api=1" +
            "&origin=\(originStr)" +
            "&destination=\(destStr)" +
            "&waypoints=\(poiStr)" +
            "&travelmode=\(gmapMode)"

        if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) {
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
