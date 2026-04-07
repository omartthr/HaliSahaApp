//
//  LocationManager.swift
//  HaliSahaApp
//
//  Konum yönetimi servisi - CoreLocation entegrasyonu
//
//  Created by Mehmet Mert Mazıcı on 1.01.2026.
//

//
//  LocationManager.swift
//  HaliSaha
//
//  Konum yönetimi servisi - CoreLocation entegrasyonu
//

import Foundation
import CoreLocation
import Combine
import UIKit

// MARK: - Location Manager
final class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: LocationError?
    @Published var isLocating = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    
    // MARK: - Computed Properties
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
    
    var defaultLocation: CLLocationCoordinate2D {
        // İstanbul merkez
        CLLocationCoordinate2D(
            latitude: AppConstants.defaultLatitude,
            longitude: AppConstants.defaultLongitude
        )
    }
    
    var currentOrDefaultLocation: CLLocationCoordinate2D {
        userLocation ?? defaultLocation
    }
    
    // MARK: - Init
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100 // 100 metre değişimde güncelle
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Request Permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Start/Stop Updates
    func startUpdatingLocation() {
        guard isAuthorized else {
            requestPermission()
            return
        }
        
        isLocating = true
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        isLocating = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Get Current Location (Async)
    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        // Eğer zaten konum varsa hemen dön
        if let location = userLocation {
            return location
        }
        
        // İzin kontrolü
        guard isAuthorized else {
            if isDenied {
                throw LocationError.permissionDenied
            }
            requestPermission()
            throw LocationError.permissionNotDetermined
        }
        
        // Konum al
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }
    
    // MARK: - Calculate Distance
    func distance(from coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLocation = userLocation else { return nil }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Kilometre cinsinden mesafe
        return userCLLocation.distance(from: targetLocation) / 1000.0
    }
    
    // MARK: - Open Settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.isLocating = false
            self.locationError = nil
            
            // Async continuation varsa tamamla
            if let continuation = self.locationContinuation {
                continuation.resume(returning: location.coordinate)
                self.locationContinuation = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLocating = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = .permissionDenied
                case .locationUnknown:
                    self.locationError = .locationUnknown
                case .network:
                    self.locationError = .networkError
                default:
                    self.locationError = .unknown(error.localizedDescription)
                }
            } else {
                self.locationError = .unknown(error.localizedDescription)
            }
            
            // Async continuation varsa hata ile tamamla
            if let continuation = self.locationContinuation {
                continuation.resume(throwing: self.locationError ?? .unknown(error.localizedDescription))
                self.locationContinuation = nil
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.locationError = .permissionDenied
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Location Error
enum LocationError: LocalizedError {
    case permissionDenied
    case permissionNotDetermined
    case locationUnknown
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Konum izni reddedildi. Ayarlardan izin verebilirsiniz."
        case .permissionNotDetermined:
            return "Konum izni henüz belirlenmedi."
        case .locationUnknown:
            return "Konumunuz belirlenemedi."
        case .networkError:
            return "Ağ hatası. İnternet bağlantınızı kontrol edin."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Coordinate Extension
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D {
    /// İki koordinat arası mesafe (km)
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to) / 1000.0
    }
}
