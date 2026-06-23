import SwiftUI
import MapKit

struct ContentView: View {
    @State private var viewModel = RouteViewModel()
    @State private var locationManager = LocationManager()
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
