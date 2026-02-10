//
//  EditUsernameView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct EditUsernameView: View {
    @State private var username: String
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
                    }
                } header: {
                    Text("Username")
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
                    .foregroundStyle(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.tertiaryText : AppColors.accent)
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
