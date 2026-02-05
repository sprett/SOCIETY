//
//  EventCreateFormContent.swift
//  SOCIETY
//
//  Form body extracted to reduce closure depth in EventCreateView.body (avoids crash at line 182/183).
//

import SwiftUI
import UIKit

extension View {
    fileprivate func glassCardStyle() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
            }
    }
}

struct EventCreateFormContent: View {
    @Binding var showLocationSearch: Bool
    @Binding var showDescriptionEditor: Bool
    @Binding var showVisibilitySheet: Bool
    @Binding var showStartDatePicker: Bool
    @Binding var showEndDatePicker: Bool
    @ObservedObject var viewModel: CreateEventViewModel
    let locationLabel: String

    var body: some View {
        VStack(spacing: 20) {
            // Restore Draft pill
            Button {
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise").font(.caption)
                    Text("Restore Draft?").font(.caption)
                    Image(systemName: "xmark").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                .overlay(
                    Capsule().strokeBorder(Color(uiColor: .separator).opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            // Media tile placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(
                            Color.secondary.opacity(0.5),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 6])))
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus").font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Upload image").font(.subheadline).foregroundStyle(.secondary)
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(
                                width: 36, height: 36)
                            Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                            Circle().strokeBorder(Color(uiColor: .separator), lineWidth: 1)
                                .frame(width: 36, height: 36)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: 280)
            .padding(.horizontal, 20)

            // Form fields
            VStack(spacing: 12) {
                TextField("Event Name", text: $viewModel.eventName)
                    .font(.body)
                    .textInputAutocapitalization(.words)
                    .glassCardStyle()

                HStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Circle().fill(Color.blue).frame(width: 10, height: 10)
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(width: 1, height: 30)
                        Circle().stroke(Color.secondary.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 10, height: 10)
                    }
                    VStack(spacing: 0) {
                        Button {
                            showStartDatePicker = true
                        } label: {
                            HStack {
                                Text("Start").foregroundStyle(.primary)
                                Spacer()
                                Text(EventDateFormatter.startDateWithTime(viewModel.startDate))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        Divider()
                        Button {
                            showEndDatePicker = true
                        } label: {
                            HStack {
                                Text("End").foregroundStyle(.primary)
                                Spacer()
                                Text(EventDateFormatter.timeOnly(viewModel.endDate))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .glassCardStyle()

                Button {
                    showLocationSearch = true
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill").font(.title3)
                            .foregroundStyle(.secondary)
                        Text(locationLabel)
                            .foregroundStyle(
                                locationLabel == "Choose Location" ? .secondary : .primary
                            )
                            .font(.body)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .glassCardStyle()

                Button {
                    showDescriptionEditor = true
                } label: {
                    HStack {
                        Image(systemName: "text.alignleft").font(.title3)
                            .foregroundStyle(.secondary)
                        if !viewModel.descriptionText.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty {
                            Text(viewModel.descriptionText).foregroundStyle(.primary).lineLimit(2)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Add Description").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .glassCardStyle()
            }
            .padding(.horizontal, 20)

            // Options section
            VStack(alignment: .leading, spacing: 12) {
                Text("Options")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Button {
                    showVisibilitySheet = true
                } label: {
                    HStack {
                        Image(systemName: viewModel.visibility == .public ? "globe" : "lock.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Visibility").foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.visibility == .public ? "Public" : "Private")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .glassCardStyle()
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 40)
        }
        .padding(.top, 16)
    }
}
