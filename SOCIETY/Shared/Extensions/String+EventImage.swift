//
//  String+EventImage.swift
//  SOCIETY
//
//  Derives thumbnail URL from main event image URL for list/map display.
//

import Foundation

extension String {

    /// Returns the thumbnail URL for list/map display when the main URL follows our storage convention.
    /// Replaces `_1024.jpg` or `_512.jpg` with `_256.jpg`. Returns self unchanged if no match
    /// (e.g. external URLs or legacy flat paths).
    var eventThumbnailURL: String {
        if contains("_1024.jpg") {
            return replacingOccurrences(of: "_1024.jpg", with: "_256.jpg")
        }
        if contains("_512.jpg") {
            return replacingOccurrences(of: "_512.jpg", with: "_256.jpg")
        }
        return self
    }
}
