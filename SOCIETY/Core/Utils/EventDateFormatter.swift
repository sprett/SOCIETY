//
//  EventDateFormatter.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 19/01/2026.
//

import Foundation

enum EventDateFormatter {
    static func dateTimeRange(start: Date, end: Date) -> String {
        let date = dateFormatter.string(from: start)
        let startTime = timeFormatter.string(from: start)
        let endTime = timeFormatter.string(from: end)
        return "\(date) · \(startTime)–\(endTime)"
    }

    static func dateOnly(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Start date with time, e.g. "Tue, Feb 3 at 17:00"
    static func startDateWithTime(_ date: Date) -> String {
        startDateTimeFormatter.string(from: date)
    }

    /// Time only, e.g. "18:00"
    static func timeOnly(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Time in 12-hour format for picker pill, e.g. "8:00 PM"
    static func timePill(_ date: Date) -> String {
        timePillFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let startDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE, MMM d 'at' HH:mm"
        return formatter
    }()

    private static let timePillFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}
