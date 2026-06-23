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
            Map(position: $position)
                .ignoresSafeArea()

            RouteInputSheet(
                viewModel: viewModel,
                locationManager: locationManager,
                onSearch: {
                    viewModel.search()
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 10, y: -2)
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
    }
}

#Preview {
    ContentView()
}
