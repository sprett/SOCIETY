//
//  LocationSearchView.swift
//  SOCIETY
//

import MapKit
import SwiftUI

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LocationSearchViewModel

    var onSelect: (String, String?, String?, CLLocationCoordinate2D) -> Void

    init(
        viewModel: LocationSearchViewModel? = nil,
        onSelect: @escaping (String, String?, String?, CLLocationCoordinate2D) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel ?? LocationSearchViewModel())
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(AppColors.danger)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
                suggestionsList
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.primaryText)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.tertiaryText)
            TextField("Search for a place", text: $viewModel.query)
                .textFieldStyle(.plain)
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(12)
        .background(
            AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var suggestionsList: some View {
        Group {
            if viewModel.isResolving {
                ProgressView()
                    .padding()
                Spacer()
            } else if viewModel.suggestions.isEmpty && !viewModel.query.isEmpty {
                Text("No results")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.suggestions) { suggestion in
                        Button {
                            Task {
                                if let result = await viewModel.resolve(suggestion) {
                                    onSelect(
                                        result.displayName,
                                        result.addressLine,
                                        result.neighborhood,
                                        result.coordinate
                                    )
                                    dismiss()
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppColors.primaryText)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

#Preview {
    LocationSearchView { _, _, _, _ in }
}
