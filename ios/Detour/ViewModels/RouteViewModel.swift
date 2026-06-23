import SwiftUI
import MapKit
import CoreLocation

@Observable
final class RouteViewModel {
    var originQuery = ""
    var destinationQuery = ""

    var originCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?

    var originName: String?
    var destinationName: String?

    var originSuggestions: [MKLocalSearchCompletion] = []
    var destinationSuggestions: [MKLocalSearchCompletion] = []

    var route: MKRoute?
    var poiResults: [POIResult] = []
    var selectedPOI: POIResult?
    var searchQuery = "coffee"
    var maxDetourMinutes: Double = 15
    var openNowOnly = true
    var selectedCategory: Category? = .coffee
    var isLoading = false
    var errorMessage: String?

    var filteredResults: [POIResult] {
        poiResults.filter { poi in
            let withinDetour = poi.detourSeconds <= Int(maxDetourMinutes) * 60
            let openFilter = !openNowOnly || poi.isOpenNow
            return withinDetour && openFilter
        }
    }

    enum Category: String, CaseIterable, Identifiable {
        case coffee = "Coffee"
        case food = "Food"
        case gas = "Gas"
        case grocery = "Grocery"
        case pharmacy = "Pharmacy"
        case evCharging = "EV Charging"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .coffee: return "cup.and.saucer.fill"
            case .food: return "fork.knife"
            case .gas: return "fuelpump.fill"
            case .grocery: return "cart.fill"
            case .pharmacy: return "cross.case.fill"
            case .evCharging: return "bolt.car.fill"
            }
        }

        var query: String {
            switch self {
            case .coffee: return "coffee"
            case .food: return "restaurant"
            case .gas: return "gas station"
            case .grocery: return "grocery store"
            case .pharmacy: return "pharmacy"
            case .evCharging: return "EV charging station"
            }
        }
    }

    var routeDurationFormatted: String? {
        guard let route else { return nil }
        let minutes = Int(route.expectedTravelTime / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)min"
        }
        return "\(minutes) min"
    }

    var routeDistanceFormatted: String? {
        guard let route else { return nil }
        let km = route.distance / 1000
        if km >= 10 {
            return String(format: "%.0f km", km)
        }
        return String(format: "%.1f km", km)
    }

    var isSearchReady: Bool {
        originCoordinate != nil && destinationCoordinate != nil
    }

    private let originCompleter = SearchCompleterDelegate()
    private let destinationCompleter = SearchCompleterDelegate()

    init() {
        originCompleter.onUpdate = { [weak self] results in
            self?.originSuggestions = results
        }
        destinationCompleter.onUpdate = { [weak self] results in
            self?.destinationSuggestions = results
        }
    }

    func updateOriginQuery(_ query: String) {
        originQuery = query
        originCoordinate = nil
        originName = nil
        originCompleter.completer.queryFragment = query
    }

    func updateDestinationQuery(_ query: String) {
        destinationQuery = query
        destinationCoordinate = nil
        destinationName = nil
        destinationCompleter.completer.queryFragment = query
    }

    func selectOrigin(_ completion: MKLocalSearchCompletion) {
        originQuery = completion.title
        originSuggestions = []
        originCompleter.completer.queryFragment = ""

        Task {
            if let coordinate = await resolveCoordinate(for: completion) {
                await MainActor.run {
                    self.originCoordinate = coordinate
                    self.originName = completion.title
                }
            }
        }
    }

    func selectDestination(_ completion: MKLocalSearchCompletion) {
        destinationQuery = completion.title
        destinationSuggestions = []
        destinationCompleter.completer.queryFragment = ""

        Task {
            if let coordinate = await resolveCoordinate(for: completion) {
                await MainActor.run {
                    self.destinationCoordinate = coordinate
                    self.destinationName = completion.title
                }
            }
        }
    }

    func useCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        originQuery = "Current Location"
        originCoordinate = coordinate
        originName = "Current Location"
        originSuggestions = []
    }

    func selectCategory(_ category: Category) {
        selectedCategory = category
        searchQuery = category.query
        if isSearchReady {
            search()
        }
    }

    func search() {
        guard let origin = originCoordinate, let destination = destinationCoordinate else { return }
        isLoading = true
        errorMessage = nil
        poiResults = []
        selectedPOI = nil

        Task {
            do {
                if route == nil {
                    let dirRequest = MKDirections.Request()
                    dirRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
                    dirRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
                    dirRequest.transportType = .automobile

                    let directionsResponse = try await MKDirections(request: dirRequest).calculate()
                    await MainActor.run {
                        self.route = directionsResponse.routes.first
                    }
                }

                let searchResponse = try await APIService.search(
                    origin: (origin.latitude, origin.longitude),
                    destination: (destination.latitude, destination.longitude),
                    query: searchQuery,
                    maxDetourMinutes: Int(maxDetourMinutes),
                    openNow: openNowOnly
                )

                await MainActor.run {
                    self.poiResults = searchResponse.results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func clear() {
        originQuery = ""
        destinationQuery = ""
        originCoordinate = nil
        destinationCoordinate = nil
        originName = nil
        destinationName = nil
        originSuggestions = []
        destinationSuggestions = []
        route = nil
        poiResults = []
        selectedPOI = nil
        errorMessage = nil
    }

    func swapOriginDestination() {
        swap(&originQuery, &destinationQuery)
        swap(&originCoordinate, &destinationCoordinate)
        swap(&originName, &destinationName)
    }

    private func resolveCoordinate(for completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            return nil
        }
    }
}

private final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let completer = MKLocalSearchCompleter()
    var onUpdate: (([MKLocalSearchCompletion]) -> Void)?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate?(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate?([])
    }
}
