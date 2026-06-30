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
    var stopResults: [StopResults] = []
    var selectedPOI: POIResult?
    var searchQuery = "coffee"
    var additionalQueries: [String] = []
    var maxDetourMinutes: Double = 15
    var openNowOnly = true
    var selectedCategory: Category? = .coffee
    var travelMode: TravelMode = .drive

    enum TravelMode: String, CaseIterable, Identifiable {
        case drive = "DRIVE"
        case walk = "WALK"
        case bike = "BICYCLE"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .drive: return "Drive"
            case .walk: return "Walk"
            case .bike: return "Bike"
            }
        }

        var icon: String {
            switch self {
            case .drive: return "car.fill"
            case .walk: return "figure.walk"
            case .bike: return "bicycle"
            }
        }

        var mkTransportType: MKDirectionsTransportType? {
            switch self {
            case .drive: return .automobile
            case .walk: return .walking
            case .bike: return nil // MapKit has no bike mode; skip client-side route
            }
        }
    }
    var isLoading = false
    var errorMessage: String?

    var filteredResults: [POIResult] {
        poiResults.filter { poi in
            let withinDetour = poi.detourSeconds <= Int(maxDetourMinutes) * 60
            let openFilter = !openNowOnly || poi.isOpenNow
            let isForward = isAheadOnRoute(poi)
            return withinDetour && openFilter && isForward
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
        guard query != originQuery else { return }
        originQuery = query
        originCoordinate = nil
        originName = nil
        originCompleter.completer.queryFragment = query
    }

    func updateDestinationQuery(_ query: String) {
        guard query != destinationQuery else { return }
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

    private var categoryDebounceTask: Task<Void, Never>?

    func selectCategory(_ category: Category) {
        selectedCategory = category
        searchQuery = category.query
        categoryDebounceTask?.cancel()
        categoryDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, isSearchReady else { return }
            await MainActor.run { search() }
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
                if route == nil, let transportType = travelMode.mkTransportType {
                    let dirRequest = MKDirections.Request()
                    dirRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
                    dirRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
                    dirRequest.transportType = transportType

                    let directionsResponse = try await MKDirections(request: dirRequest).calculate()
                    await MainActor.run {
                        self.route = directionsResponse.routes.first
                    }
                }

                let allQueries = additionalQueries.isEmpty ? nil : [searchQuery] + additionalQueries
                let searchResponse = try await APIService.search(
                    origin: (origin.latitude, origin.longitude),
                    destination: (destination.latitude, destination.longitude),
                    query: searchQuery,
                    queries: allQueries,
                    maxDetourMinutes: Int(maxDetourMinutes),
                    openNow: openNowOnly,
                    travelMode: travelMode.rawValue
                )

                await MainActor.run {
                    self.poiResults = searchResponse.results
                    self.stopResults = searchResponse.stops ?? []
                    if searchResponse.results.isEmpty {
                        self.errorMessage = "No places found along this route. Try a different category."
                    }
                    self.isLoading = false
                    AnalyticsService.shared.track("search_executed", properties: [
                        "category": self.selectedCategory?.rawValue ?? "custom",
                        "travelMode": self.travelMode.rawValue,
                        "resultCount": searchResponse.results.count,
                    ])
                    if let o = self.originCoordinate, let d = self.destinationCoordinate {
                        RecentSearchStore.shared.add(
                            originName: self.originName ?? "Origin",
                            origin: o,
                            destinationName: self.destinationName ?? "Destination",
                            destination: d,
                            category: self.searchQuery
                        )
                    }
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

    func loadSavedRoute(_ saved: SavedRoute) {
        originQuery = saved.originName
        originCoordinate = saved.originCoordinate
        originName = saved.originName
        destinationQuery = saved.destinationName
        destinationCoordinate = saved.destinationCoordinate
        destinationName = saved.destinationName
        originSuggestions = []
        destinationSuggestions = []
        route = nil

        if let cat = Category.allCases.first(where: { $0.query == saved.defaultCategory }) {
            selectedCategory = cat
            searchQuery = cat.query
        }

        search()
    }

    func addStop(_ category: Category) {
        if !additionalQueries.contains(category.query) {
            additionalQueries.append(category.query)
            if isSearchReady { search() }
        }
    }

    func removeStop(at index: Int) {
        guard index < additionalQueries.count else { return }
        additionalQueries.remove(at: index)
        if isSearchReady { search() }
    }

    func clearStops() {
        additionalQueries.removeAll()
        stopResults.removeAll()
    }

    func loadRecentSearch(_ recent: RecentSearch) {
        originQuery = recent.originName
        originCoordinate = recent.originCoordinate
        originName = recent.originName
        destinationQuery = recent.destinationName
        destinationCoordinate = recent.destinationCoordinate
        destinationName = recent.destinationName
        originSuggestions = []
        destinationSuggestions = []
        route = nil

        if let cat = Category.allCases.first(where: { $0.query == recent.category }) {
            selectedCategory = cat
            searchQuery = cat.query
        }

        search()
    }

    func saveCurrentRoute(name: String) -> SavedRoute? {
        guard let origin = originCoordinate,
              let destination = destinationCoordinate,
              let oName = originName,
              let dName = destinationName else { return nil }

        let route = SavedRoute.create(
            name: name,
            origin: origin,
            originName: oName,
            destination: destination,
            destinationName: dName,
            defaultCategory: searchQuery
        )
        SavedRoutesStore.shared.save(route)
        return route
    }

    private func isAheadOnRoute(_ poi: POIResult) -> Bool {
        guard let polyline = route?.polyline else { return true }
        let pointCount = polyline.pointCount
        guard pointCount > 1 else { return true }

        let poiMapPoint = MKMapPoint(poi.coordinate)
        var closestIndex = 0
        var closestDistance = Double.greatestFiniteMagnitude

        for i in 0..<pointCount {
            let routePoint = polyline.points()[i]
            let dist = poiMapPoint.distance(to: routePoint)
            if dist < closestDistance {
                closestDistance = dist
                closestIndex = i
            }
        }

        let progress = Double(closestIndex) / Double(pointCount - 1)
        return progress > 0.05
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
