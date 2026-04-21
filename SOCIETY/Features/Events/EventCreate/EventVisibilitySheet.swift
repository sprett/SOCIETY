//
//  EventVisibilitySheet.swift
//  SOCIETY
//

import SwiftUI

/// Event Visibility sheet content matching the Luma-style design: icon, title,
/// intro, Public/Private options, Confirm.
struct EventVisibilitySheetContent: View {
    let initialVisibility: EventVisibility
    let onConfirm: (EventVisibility) -> Void
    let onDismiss: () -> Void

    @State private var selectedVisibility: EventVisibility

    init(
        initialVisibility: EventVisibility,
        onConfirm: @escaping (EventVisibility) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.initialVisibility = initialVisibility
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        _selectedVisibility = State(initialValue: initialVisibility)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 44, height: 44)
                        .background(AppColors.surface, in: Circle())
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .liquidGlassCircle()
                    .clipShape(Circle())
                }

                Text("Event Visibility")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.primaryText)

                Text(
                    "Choose how this event shows up within SOCIETY. People with the direct link to the event can always access it."
                )
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    visibilityRow(
                        title: "Public",
                        description: "Shown on SOCIETY events feed. Eligible to be featured.",
                        isSelected: selectedVisibility == .public
                    ) {
                        selectedVisibility = .public
                    }
                    Divider().background(AppColors.divider)
                    visibilityRow(
                        title: "Private",
                        description: "Only people invited or with the link can register.",
                        isSelected: selectedVisibility == .private
                    ) {
                        selectedVisibility = .private
                    }
                }
                .background(
                    AppColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    onConfirm(selectedVisibility)
                } label: {
                    Text("Confirm")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(
                    AppColors.primaryText,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .liquidGlassCard(cornerRadius: 24)
        .ignoresSafeArea(edges: .all)
    }

    private func visibilityRow(
        title: String,
        description: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(AppColors.divider, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppColors.primaryText)
                            .frame(width: 14, height: 14)
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppColors.background)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
