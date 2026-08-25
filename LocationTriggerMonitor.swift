import Foundation
import CoreLocation

/// 轻量级地点触发器：仅在 App 存在未触发的地点任务时启动。
final class LocationTriggerMonitor: NSObject, CLLocationManagerDelegate {
    static let shared = LocationTriggerMonitor()

    private let manager = CLLocationManager()
    var onLocationUpdate: ((CLLocation) -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAuthorizationIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startMonitoringIfNeeded() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startMonitoringSignificantLocationChanges()
        } else {
            requestAuthorizationIfNeeded()
        }
    }

    func requestLocationUpdate() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else {
            requestAuthorizationIfNeeded()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            Task { @MainActor in
                self.startMonitoringIfNeeded()
                self.requestLocationUpdate()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.onLocationUpdate?(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location monitor error: \(error.localizedDescription)")
    }
}
