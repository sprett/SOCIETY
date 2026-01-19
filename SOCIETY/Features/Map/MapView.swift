//
//  MapView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import MapKit
import SwiftUI

struct MapView: View {
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        NavigationStack {
            Map(position: $position)
                .ignoresSafeArea(edges: [.top, .bottom])
        }
    }
}

#Preview {
    MapView()
}
