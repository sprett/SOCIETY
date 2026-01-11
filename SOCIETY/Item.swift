//
//  Item.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
