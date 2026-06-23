import SwiftUI
import MapKit

struct ContentView: View {
    @State private var viewModel = RouteViewModel()
    @State private var locationManager = LocationManager()
    @State private var navigatingPOI: POIResult?
    @State private var showNavSheet = false
    @State private var showResults = false
    @State private var detourRoute: MKRoute?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            mapView
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                }

                bottomPanel
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
        }
        .onChange(of: viewModel.route) {
            fitRouteOnMap()
            if viewModel.route != nil {
                showResults = true
            }
        }
        .sheet(isPresented: $showResults) {
            resultsSheet
                .presentationDetents([.medium, .large, .fraction(0.35)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .confirmationDialog(
            "Navigate to \(navigatingPOI?.name ?? "")",
            isPresented: $showNavSheet,
            titleVisibility: .visible
        ) {
            ForEach(NavigationApp.available) { app in
                Button(app.rawValue) {
                    if let poi = navigatingPOI {
                        NavigationService.navigate(
                            to: poi,
                            from: viewModel.originCoordinate,
                            destination: viewModel.destinationCoordinate,
                            using: app
                        )
                    }
                }
            }
            if let poi = navigatingPOI {
                Button("Copy Address") {
                    NavigationService.copyAddress(poi)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $position) {
            if let route = viewModel.route {
                MapPolyline(route.polyline)
                    .stroke(.blue.opacity(detourRoute != nil ? 0.3 : 1.0), lineWidth: 5)
            }

            if let detourRoute {
                MapPolyline(detourRoute.polyline)
                    .stroke(.orange, lineWidth: 5)
            }

            ForEach(viewModel.filteredResults) { poi in
                Annotation(poi.name, coordinate: poi.coordinate) {
                    DetourBadge(poi: poi, isSelected: viewModel.selectedPOI == poi)
                        .onTapGesture {
                            selectPOI(poi)
                        }
                        .accessibilityLabel("\(poi.name), \(poi.detourFormatted) detour")
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Bottom Panel (route input + trip info)

    private var bottomPanel: some View {
        VStack(spacing: 8) {
            if viewModel.route != nil {
                HStack(spacing: 8) {
                    tripInfoPill

                    if detourRoute != nil {
                        Button {
                            clearDetourRoute()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Clear detour")
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                        }
                    }

                    Spacer()

                    Button {
                        showResults = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12))
                            Text("\(viewModel.filteredResults.count)")
                                .font(.caption.weight(.bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }

            RouteInputSheet(
                viewModel: viewModel,
                locationManager: locationManager,
                onSearch: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    detourRoute = nil
                    viewModel.search()
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 10, y: -2)
        }
    }

    // MARK: - Results Sheet

    private var resultsSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryBar(viewModel: viewModel)
                    .padding(.vertical, 8)

                FiltersBar(viewModel: viewModel)
                    .padding(.bottom, 8)

                Divider()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Searching along route...")
                    Spacer()
                } else if viewModel.filteredResults.isEmpty && !viewModel.poiResults.isEmpty {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No places within \(Int(viewModel.maxDetourMinutes)) min")
                            .font(.subheadline.weight(.medium))
                        Text("Try increasing the max detour")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if viewModel.filteredResults.isEmpty {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No places found")
                            .font(.subheadline.weight(.medium))
                        Button("Retry") { viewModel.search() }
                            .font(.caption.weight(.medium))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredResults) { poi in
                            POIResultRow(
                                poi: poi,
                                isSelected: viewModel.selectedPOI == poi,
                                onNavigate: { navigateTo($0) }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectPOI(poi)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("\(viewModel.filteredResults.count) places found")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showResults = false
                    }
                }
            }
        }
    }

    // MARK: - POI Selection & Detour Route

    private func selectPOI(_ poi: POIResult) {
        viewModel.selectedPOI = poi
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard let origin = viewModel.originCoordinate,
              let destination = viewModel.destinationCoordinate else { return }

        Task {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .automobile

            let waypoint = MKMapItem(placemark: MKPlacemark(coordinate: poi.coordinate))
            waypoint.name = poi.name

            let leg1Request = MKDirections.Request()
            leg1Request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            leg1Request.destination = waypoint
            leg1Request.transportType = .automobile

            let leg2Request = MKDirections.Request()
            leg2Request.source = waypoint
            leg2Request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            leg2Request.transportType = .automobile

            async let leg1 = MKDirections(request: leg1Request).calculate()
            async let leg2 = MKDirections(request: leg2Request).calculate()

            if let r1 = try? await leg1.routes.first,
               let r2 = try? await leg2.routes.first {
                await MainActor.run {
                    self.detourRoute = r1
                    fitDetourOnMap(leg1: r1, leg2: r2, poi: poi)
                }
            }
        }
    }

    private func clearDetourRoute() {
        detourRoute = nil
        viewModel.selectedPOI = nil
        fitRouteOnMap()
    }

    private func fitDetourOnMap(leg1: MKRoute, leg2: MKRoute, poi: POIResult) {
        let rect1 = leg1.polyline.boundingMapRect
        let rect2 = leg2.polyline.boundingMapRect
        let combined = rect1.union(rect2)
        let padded = combined.insetBy(dx: -combined.size.width * 0.15, dy: -combined.size.height * 0.15)
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .rect(padded)
        }
    }

    // MARK: - Navigation Handoff

    private func navigateTo(_ poi: POIResult) {
        let available = NavigationApp.available
        if available.count == 1 {
            NavigationService.navigate(
                to: poi,
                from: viewModel.originCoordinate,
                destination: viewModel.destinationCoordinate,
                using: available[0]
            )
        } else {
            navigatingPOI = poi
            showNavSheet = true
        }
    }

    // MARK: - Trip Info

    private var tripInfoPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "car.fill")
                .font(.system(size: 12))
            if let duration = viewModel.routeDurationFormatted,
               let distance = viewModel.routeDistanceFormatted {
                Text("\(duration) · \(distance)")
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Error

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button("Retry") { viewModel.search() }
                .font(.subheadline.weight(.medium))
            Button("Dismiss") { viewModel.errorMessage = nil }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Map Fit

    private func fitRouteOnMap() {
        guard let route = viewModel.route else { return }
        let rect = route.polyline.boundingMapRect
        let padded = rect.insetBy(dx: -rect.size.width * 0.15, dy: -rect.size.height * 0.25)
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .rect(padded)
        }
    }
}

#Preview {
    ContentView()
}
