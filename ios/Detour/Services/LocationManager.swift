import CoreLocation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: String?

    private let manager = CLLocationManager()
    private var retryCount = 0
    private let maxRetries = 3

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isPermissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestPermission() {
        locationError = nil
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        locationError = nil
        retryCount = 0
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
        locationError = nil
        retryCount = 0
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if retryCount < maxRetries {
            retryCount += 1
            manager.stopUpdatingLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.manager.startUpdatingLocation()
            }
        } else {
            locationError = "Couldn't get your location. Check Settings > Privacy > Location Services."
            manager.stopUpdatingLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            requestLocation()
        } else if manager.authorizationStatus == .denied {
            locationError = "Location access denied. Enable it in Settings > Privacy > Location Services."
        }
    }
}
