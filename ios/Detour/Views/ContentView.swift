import SwiftUI
import MapKit

struct ContentView: View {
    @State private var viewModel = RouteViewModel()
    @State private var locationManager = LocationManager()
    @State private var navigatingPOI: POIResult?
    @State private var showNavSheet = false
    @State private var showResults = false
    @State private var detourLeg1: MKRoute?
    @State private var detourLeg2: MKRoute?
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    private var hasDetour: Bool { detourLeg1 != nil }

    var body: some View {
        ZStack(alignment: .top) {
            mapView
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if viewModel.isLoading && !showResults {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Searching...")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }

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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: viewModel.route) {
            fitRouteOnMap()
            if viewModel.route != nil {
                showResults = true
            }
        }
        .onChange(of: viewModel.poiResults) {
            if !viewModel.poiResults.isEmpty {
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
                            originName: viewModel.originName,
                            destination: viewModel.destinationCoordinate,
                            destinationName: viewModel.destinationName,
                            travelMode: viewModel.travelMode.rawValue,
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
                    .stroke(.blue.opacity(hasDetour ? 0.3 : 1.0), lineWidth: 5)
            }

            if let detourLeg1 {
                MapPolyline(detourLeg1.polyline)
                    .stroke(.orange, lineWidth: 5)
            }

            if let detourLeg2 {
                MapPolyline(detourLeg2.polyline)
                    .stroke(.orange, lineWidth: 5)
            }

            if let selectedPOI = viewModel.selectedPOI,
               let origin = viewModel.originCoordinate,
               let destination = viewModel.destinationCoordinate {
                Annotation("Start", coordinate: origin) {
                    WaypointMarker("A", color: .green, label: "Start")
                }
                Annotation(selectedPOI.name, coordinate: selectedPOI.coordinate) {
                    WaypointMarker("B", color: .orange, label: selectedPOI.name)
                        .onTapGesture { clearDetourRoute() }
                }
                Annotation("End", coordinate: destination) {
                    WaypointMarker("C", color: .red, label: "End")
                }
            }

            ForEach(viewModel.filteredResults) { poi in
                let isSelected = viewModel.selectedPOI == poi
                let hasSelection = viewModel.selectedPOI != nil

                if !isSelected {
                    Annotation("", coordinate: poi.coordinate) {
                        DetourBadge(poi: poi, isSelected: false)
                            .opacity(hasSelection ? 0.2 : 1.0)
                            .scaleEffect(hasSelection ? 0.6 : 1.0)
                            .animation(.easeInOut(duration: 0.25), value: hasSelection)
                            .onTapGesture {
                                selectPOI(poi)
                            }
                            .accessibilityLabel("\(poi.name), \(poi.detourFormatted) detour")
                    }
                }
            }
        }
        .mapControls {
            MapCompass()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 140)
        }
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 8) {
            if viewModel.route != nil {
                HStack(spacing: 8) {
                    tripInfoPill
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
                    clearDetourRoute()
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
                if hasDetour, let poi = viewModel.selectedPOI {
                    HStack(spacing: 8) {
                        tripInfoPill

                        Button {
                            navigateTo(poi)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Open in Maps")
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.blue, in: Capsule())
                            .foregroundStyle(.white)
                        }

                        Spacer()

                        Button {
                            clearDetourRoute()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

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
                            Button {
                                selectPOI(poi)
                            } label: {
                                POIResultRow(
                                    poi: poi,
                                    isSelected: viewModel.selectedPOI == poi,
                                    onNavigate: { navigateTo($0) }
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("\(viewModel.filteredResults.count) places found")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        sendFeedback()
                    } label: {
                        Image(systemName: "envelope")
                            .font(.system(size: 14))
                    }
                }
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
        AnalyticsService.shared.track("poi_selected", properties: [
            "detourSeconds": poi.detourSeconds,
            "rating": poi.rating,
        ])

        guard let origin = viewModel.originCoordinate,
              let destination = viewModel.destinationCoordinate else { return }

        let waypoint = MKMapItem(placemark: MKPlacemark(coordinate: poi.coordinate))
        waypoint.name = poi.name

        Task {
            let leg1Request = MKDirections.Request()
            leg1Request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            leg1Request.destination = waypoint
            leg1Request.transportType = .automobile

            let leg2Request = MKDirections.Request()
            leg2Request.source = waypoint
            leg2Request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            leg2Request.transportType = .automobile

            async let leg1Task = MKDirections(request: leg1Request).calculate()
            async let leg2Task = MKDirections(request: leg2Request).calculate()

            if let r1 = try? await leg1Task.routes.first,
               let r2 = try? await leg2Task.routes.first {
                await MainActor.run {
                    self.detourLeg1 = r1
                    self.detourLeg2 = r2
                    fitDetourOnMap(leg1: r1, leg2: r2)
                }
            }
        }
    }

    private func clearDetourRoute() {
        detourLeg1 = nil
        detourLeg2 = nil
        viewModel.selectedPOI = nil
        fitRouteOnMap()
    }

    private func fitDetourOnMap(leg1: MKRoute, leg2: MKRoute) {
        let combined = leg1.polyline.boundingMapRect.union(leg2.polyline.boundingMapRect)
        // Extra bottom padding so the route shows above the sheet
        let padded = MKMapRect(
            x: combined.origin.x - combined.size.width * 0.15,
            y: combined.origin.y - combined.size.height * 0.6,
            width: combined.size.width * 1.3,
            height: combined.size.height * 2.0
        )
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
                originName: viewModel.originName,
                destination: viewModel.destinationCoordinate,
                destinationName: viewModel.destinationName,
                travelMode: viewModel.travelMode.rawValue,
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
            Image(systemName: viewModel.travelMode.icon)
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

    // MARK: - Feedback

    private func sendFeedback() {
        let subject = "OnRoute Beta Feedback"
        let body = "\n\n---\nOnRoute v1.0.0 (iOS \(UIDevice.current.systemVersion))"
        let mailto = "mailto:ahmed.khaled.a.mohamed@gmail.com?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: mailto) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Map Fit

    private func fitRouteOnMap() {
        guard let route = viewModel.route else { return }
        let rect = route.polyline.boundingMapRect
        // Bias upward so route is visible above the bottom panel + sheet
        let padded = MKMapRect(
            x: rect.origin.x - rect.size.width * 0.15,
            y: rect.origin.y - rect.size.height * 0.5,
            width: rect.size.width * 1.3,
            height: rect.size.height * 1.8
        )
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .rect(padded)
        }
    }
}

#Preview {
    ContentView()
}
