import SwiftUI
import MapKit

struct ContentView: View {
    @State private var viewModel = RouteViewModel()
    @State private var locationManager = LocationManager()
    @State private var navigatingPOI: POIResult?
    @State private var showNavSheet = false
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                if let route = viewModel.route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 5)
                }

                ForEach(viewModel.filteredResults) { poi in
                    Annotation(poi.name, coordinate: poi.coordinate) {
                        DetourBadge(poi: poi, isSelected: viewModel.selectedPOI == poi)
                            .onTapGesture {
                                viewModel.selectedPOI = poi
                            }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if let route = viewModel.route {
                    tripInfoPill(route: route)
                        .padding(.bottom, 8)
                }

                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                        .padding(.bottom, 8)
                }

                if viewModel.route != nil {
                    CategoryBar(viewModel: viewModel)
                        .padding(.vertical, 6)

                    FiltersBar(viewModel: viewModel)
                        .padding(.bottom, 6)
                }

                if !viewModel.filteredResults.isEmpty {
                    resultsList
                }

                RouteInputSheet(
                    viewModel: viewModel,
                    locationManager: locationManager,
                    onSearch: {
                        viewModel.search()
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 10, y: -2)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .onChange(of: viewModel.route) {
            fitRouteOnMap()
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

    private var resultsList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(viewModel.filteredResults.count) places found")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredResults) { poi in
                        POIResultRow(
                            poi: poi,
                            isSelected: viewModel.selectedPOI == poi,
                            onNavigate: { navigateTo($0) }
                        )
                        .onTapGesture {
                            viewModel.selectedPOI = poi
                            withAnimation {
                                position = .region(MKCoordinateRegion(
                                    center: poi.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            }
                        }
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 8)
    }

    private func tripInfoPill(route: MKRoute) -> some View {
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

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button("Dismiss") {
                viewModel.errorMessage = nil
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func fitRouteOnMap() {
        guard let route = viewModel.route else { return }
        let rect = route.polyline.boundingMapRect
        let paddedRect = rect.insetBy(dx: -rect.size.width * 0.2, dy: -rect.size.height * 0.3)
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .rect(paddedRect)
        }
    }
}

#Preview {
    ContentView()
}
