//
//  Event.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Foundation

struct Event: Identifiable, Hashable {
    let id: UUID
    let title: String
    let category: String
    let startDate: Date
    let venueName: String
    let neighborhood: String
    let distanceKm: Double
    let imageNameOrURL: String
    let isFeatured: Bool
}
