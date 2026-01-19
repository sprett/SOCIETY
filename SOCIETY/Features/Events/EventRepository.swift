//
//  EventRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 19/01/2026.
//

import Foundation

protocol EventRepository {
    func fetchEvents() async throws -> [Event]
}
