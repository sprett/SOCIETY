//
//  AvatarSelection.swift
//  SOCIETY
//

import Foundation

enum AvatarSelectionSource: String {
    case dicebear
    case upload
}

struct AvatarSelection {
    let source: AvatarSelectionSource
    let seed: String?
    let style: String?
    let imageData: Data
    let contentType: String
}
