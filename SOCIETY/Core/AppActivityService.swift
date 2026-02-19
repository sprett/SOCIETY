//
//  AppActivityService.swift
//  SOCIETY
//
//  Reports app open and heartbeat to Supabase for admin dashboard (users_online, last_app_open_at).
//  Uses device location when available, otherwise Edge Function falls back to IP geolocation.
//

import CoreLocation
import Foundation
import Supabase

final class AppActivityService {
    private let client: SupabaseClient
    private let locationManager: LocationManager

    init(client: SupabaseClient, locationManager: LocationManager) {
        self.client = client
        self.locationManager = locationManager
    }

    /// Call on app launch/foreground and periodically while active. Updates last_app_open_at,
    /// last_seen_at, last_known_lat/lng (from device or IP), and logs to app_open_events.
    func reportActivity() async {
        do {
            let session = try await client.auth.session
            client.functions.setAuth(token: session.accessToken)

            var options = FunctionInvokeOptions()
            if let coord = await locationManager.requestLocationOnce() {
                options = FunctionInvokeOptions(body: ["latitude": coord.latitude, "longitude": coord.longitude])
            }
            try await client.functions.invoke("report-app-activity", options: options)
        } catch {
            // Fallback to RPC so live user count still works if Edge Function fails
            _ = try? await client.rpc("report_app_activity").execute()
        }
    }
}
