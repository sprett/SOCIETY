//
//  EventModels.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Foundation

struct Event: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let location: String
    let rsvpStatus: RSVPStatus
    
    enum RSVPStatus: String {
        case going = "Going"
        case notGoing = "Not Going"
        case maybe = "Maybe"
    }
}
