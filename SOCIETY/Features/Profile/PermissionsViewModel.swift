//
//  PermissionsViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import AVFoundation
import Combine
import Contacts
import CoreLocation
import SwiftUI

@MainActor
final class PermissionsViewModel: ObservableObject {
    @Published var cameraStatus: String = ""
    @Published var locationStatus: String = ""
    @Published var contactsStatus: String = ""

    private let locationManager = CLLocationManager()

    func refresh() {
        cameraStatus = cameraAuthorizationStatusString
        locationStatus = locationAuthorizationStatusString
        contactsStatus = contactsAuthorizationStatusString
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var cameraAuthorizationStatusString: String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    private var locationAuthorizationStatusString: String {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return "Allowed"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    private var contactsAuthorizationStatusString: String {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }
}
