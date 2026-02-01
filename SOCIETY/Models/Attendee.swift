//
//  Attendee.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 01/02/2026.
//

import Foundation

struct Attendee: Identifiable, Hashable {
    let id: UUID
    let name: String?
    let avatarURL: String?
}
