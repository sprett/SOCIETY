//
//  EditPhoneNumberView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct EditPhoneNumberView: View {
    @State private var phoneNumber: String
    @FocusState private var isFocused: Bool
    private let onSave: (String) -> Void
    private let onDismiss: () -> Void

    init(
        currentPhone: String,
        onSave: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _phoneNumber = State(initialValue: currentPhone)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .focused($isFocused)
                } header: {
                    Text("Phone Number")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Edit Phone Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(AppColors.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
