//
//  MinuteIntervalDatePicker.swift
//  SOCIETY
//

import SwiftUI
import UIKit

/// Wheel date/time picker with time restricted to 15-minute intervals.
struct MinuteIntervalDatePicker: UIViewRepresentable {
    @Binding var date: Date
    var minuteInterval: Int = 15

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.minuteInterval = minuteInterval
        picker.preferredDatePickerStyle = .wheels
        picker.addTarget(
            context.coordinator, action: #selector(Coordinator.valueChanged), for: .valueChanged)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        picker.date = date
        picker.minuteInterval = minuteInterval
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(date: $date)
    }

    class Coordinator: NSObject {
        var date: Binding<Date>
        init(date: Binding<Date>) { self.date = date }
        @objc func valueChanged(_ sender: UIDatePicker) { date.wrappedValue = sender.date }
    }
}
