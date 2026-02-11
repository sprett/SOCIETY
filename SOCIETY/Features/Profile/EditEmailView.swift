//
//  EditEmailView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct EditEmailView: View {
    @State private var email: String
    @FocusState private var isFocused: Bool
    private let onSave: (String) -> Void
    private let onDismiss: () -> Void

    init(
        currentEmail: String,
        onSave: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _email = State(initialValue: currentEmail)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                } header: {
                    Text("Email")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Edit Email")
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
                        onSave(email.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .foregroundStyle(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.tertiaryText : AppColors.accent)
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
