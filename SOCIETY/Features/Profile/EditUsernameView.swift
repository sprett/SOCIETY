//
//  EditUsernameView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct EditUsernameView: View {
    @State private var username: String
    @State private var validationError: String?
    @FocusState private var isFocused: Bool
    private let onSave: (String) -> Void
    private let onDismiss: () -> Void

    init(
        currentUsername: String,
        onSave: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _username = State(initialValue: currentUsername)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }
    
    private var isValid: Bool {
        UsernameValidator.isValid(username)
    }
    
    private func validate() {
        validationError = UsernameValidator.validationError(for: username)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("@")
                            .foregroundStyle(AppColors.secondaryText)
                        TextField("username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isFocused)
                            .onChange(of: username) { _, newValue in
                                // Filter to only allow valid characters: alphanumeric, _, -, .
                                username = UsernameValidator.filter(newValue)
                                validate()
                            }
                    }
                } header: {
                    Text("Username")
                } footer: {
                    if let error = validationError {
                        Text(error)
                            .foregroundStyle(AppColors.danger)
                    } else {
                        Text("Lowercase only. Start/end with letter or number.")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Edit Username")
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
                        onSave(username.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .foregroundStyle(isValid ? AppColors.accent : AppColors.tertiaryText)
                    .disabled(!isValid)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
