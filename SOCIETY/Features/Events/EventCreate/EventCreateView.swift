//
//  EventCreateView.swift
//  SOCIETY
//

import MapKit
import PhotosUI
import SwiftUI
import UIKit

private func _glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 16)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
}


private struct CreateEventFormFieldsView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    @Binding var showStartDatePicker: Bool
    @Binding var showEndDatePicker: Bool
    @Binding var showLocationSearch: Bool
    @Binding var showDescriptionEditor: Bool

    var body: some View {
        VStack(spacing: 12) {
            _glassCard {
                TextField("Event Name", text: $viewModel.eventName)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppColors.primaryText)
            }

            _glassCard {
                VStack(spacing: 0) {
                    Button {
                        showStartDatePicker = true
                    } label: {
                        HStack {
                            Text("Start")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                            Spacer()
                            Text(EventDateFormatter.startDateWithTime(viewModel.startDate))
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .background(AppColors.divider)
                    Button {
                        showEndDatePicker = true
                    } label: {
                        HStack {
                            Text("End")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                            Spacer()
                            Text(EventDateFormatter.timeOnly(viewModel.endDate))
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }

            _glassCard {
                Button {
                    showLocationSearch = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(AppColors.tertiaryText)
                        Text(viewModel.selectedLocation?.displayName ?? "Choose Location")
                            .font(.subheadline)
                            .foregroundStyle(
                                viewModel.selectedLocation != nil
                                    ? AppColors.primaryText : AppColors.secondaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            _glassCard {
                Button {
                    showDescriptionEditor = true
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(AppColors.tertiaryText)
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.descriptionText.isEmpty {
                                Text("Add Description")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.secondaryText)
                            } else {
                                Text(truncatedDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.primaryText)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Category picker
            _glassCard {
                Button {
                    viewModel.isShowingCategoryPicker = true
                } label: {
                    HStack(spacing: 12) {
                        if let cat = viewModel.selectedCategory {
                            Image(systemName: cat.iconIdentifier)
                                .foregroundStyle(cat.accentColor)
                        } else {
                            Image(systemName: "tag")
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                        Text(viewModel.selectedCategory?.name ?? "Choose Category")
                            .font(.subheadline)
                            .foregroundStyle(
                                viewModel.selectedCategory != nil
                                    ? AppColors.primaryText : AppColors.secondaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $viewModel.isShowingCategoryPicker) {
                EventCreateCategoryPickerSheet(
                    categories: viewModel.availableCategories,
                    selectedCategory: $viewModel.selectedCategory
                )
            }
        }
    }

    private var truncatedDescription: String {
        let t = viewModel.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 80 { return t }
        return String(t.prefix(80)) + "…"
    }
}

// MARK: - Category Picker Sheet

// CategoryPickerSheet moved to EventCreateCategoryPickerSheet.swift (renamed
// EventCreateCategoryPickerSheet).


@MainActor
struct EventCreateView: View {
    @ObservedObject var viewModel: CreateEventViewModel

    private let authSession: AuthSessionStore
    private let customDismiss: (() -> Void)?

    init(
        viewModel: CreateEventViewModel,
        authSession: AuthSessionStore,
        onDismiss: (() -> Void)? = nil
    ) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        self.authSession = authSession
        self.customDismiss = onDismiss
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                topBar
                mediaTile
                CreateEventFormFieldsView(
                    viewModel: viewModel,
                    showStartDatePicker: $viewModel.isShowingStartDatePicker,
                    showEndDatePicker: $viewModel.isShowingEndDatePicker,
                    showLocationSearch: $viewModel.isShowingLocationSearch,
                    showDescriptionEditor: $viewModel.isShowingDescriptionEditor
                )
                optionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(createEventBackground)
        // Cover image preprocessing is handled by CreateEventViewModel's Combine pipeline.
        // No need for onChange here; the ViewModel observes coverPickerItem directly.
        .sheet(isPresented: $viewModel.isShowingStartDatePicker) {
            dateTimePickerSheet(
                date: $viewModel.startDate,
                title: "Start",
                onDone: { viewModel.setStartDate($0) }
            )
        }
        .sheet(isPresented: $viewModel.isShowingEndDatePicker) {
            dateTimePickerSheet(
                date: $viewModel.endDate,
                title: "End",
                onDone: { viewModel.setEndDate($0) }
            )
        }
        .sheet(isPresented: $viewModel.isShowingLocationSearch) {
            LocationSearchView { displayName, addressLine, neighborhood, coordinate in
                viewModel.selectLocation(
                    displayName: displayName,
                    addressLine: addressLine,
                    neighborhood: neighborhood,
                    coordinate: coordinate
                )
                viewModel.isShowingLocationSearch = false
            }
        }
        .sheet(isPresented: $viewModel.isShowingDescriptionEditor) {
            RichTextEditorView(text: $viewModel.descriptionText)
        }
        .sheet(isPresented: $viewModel.isShowingVisibilitySheet) {
            EventVisibilitySheetContent(
                initialVisibility: viewModel.visibility,
                onConfirm: {
                    viewModel.setVisibility($0)
                    viewModel.isShowingVisibilitySheet = false
                },
                onDismiss: { viewModel.isShowingVisibilitySheet = false }
            )
            .presentationDetents([.height(420)])
        }
        .alert("Couldn't create event", isPresented: viewModel.binding(\.isCreateErrorPresented)) {
            Button("OK") {
                viewModel.createErrorMessage = nil
                viewModel.isCreateErrorPresented = false
            }
        } message: {
            if let msg = viewModel.createErrorMessage {
                Text(msg)
            }
        }
    }

    private var createEventBackground: some View {
        (Color(lightColor: Color(uiColor: .systemGray6), darkColor: Color.white.opacity(0.06)))
            .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                customDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .frame(width: 44, height: 44)
            .background(liquidGlassCircleBackground)
            .clipShape(Circle())

            Spacer()

            Text("Create Event")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                Task { await viewModel.createEvent() }
            } label: {
                Group {
                    if viewModel.isCreating {
                        ProgressView()
                            .tint(AppColors.primaryText)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(
                viewModel.isFormValid && !viewModel.isCreating
                    ? AppColors.primaryText : AppColors.tertiaryText
            )
            .opacity(viewModel.isFormValid && !viewModel.isCreating ? 1 : 0.5)
            .disabled(!viewModel.isFormValid || viewModel.isCreating)
            .frame(width: 44, height: 44)
            .background(liquidGlassCircleBackground)
            .clipShape(Circle())
        }
        .padding(.vertical, 8)
        .alert("Couldn't create event", isPresented: viewModel.binding(\.isCreateErrorPresented)) {
            Button("OK") {
                viewModel.createErrorMessage = nil
                viewModel.isCreateErrorPresented = false
            }
        } message: {
            if let msg = viewModel.createErrorMessage {
                Text(msg)
            }
        }
    }

    @ViewBuilder
    private var liquidGlassCircleBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular, in: .circle)
        } else {
            Color.clear.background(.ultraThinMaterial, in: Circle())
        }
    }

    private var mediaTile: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if viewModel.isProcessingCoverImage {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Processing...")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(width: side, height: side)
                    .background(AppColors.surface.opacity(0.5))
                } else if let data = viewModel.coverImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipped()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title)
                            .foregroundStyle(AppColors.tertiaryText)
                        Text("Upload image")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(width: side, height: side)
                    .background(AppColors.surface.opacity(0.5))
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        AppColors.divider,
                        style: viewModel.coverImageData == nil && !viewModel.isProcessingCoverImage
                            ? StrokeStyle(lineWidth: 2, dash: [8, 4])
                            : StrokeStyle(lineWidth: 1)
                    )
            }
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(
                    selection: $viewModel.coverPickerItem,
                    matching: .images
                ) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.primaryText)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessingCoverImage)
                .padding(12)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OPTIONS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
            _glassCard {
                Button {
                    viewModel.isShowingVisibilitySheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "eye")
                            .foregroundStyle(AppColors.tertiaryText)
                        Text("Visibility")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(viewModel.visibility == .public ? "Public" : "Private")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func dateTimePickerSheet(
        date: Binding<Date>,
        title: String,
        onDone: @escaping (Date) -> Void
    ) -> some View {
        NavigationStack {
            MinuteIntervalDatePicker(date: date)
                .frame(maxWidth: .infinity)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            if title == "Start" {
                                viewModel.isShowingStartDatePicker = false
                            } else {
                                viewModel.isShowingEndDatePicker = false
                            }
                        }
                        .foregroundStyle(AppColors.primaryText)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onDone(date.wrappedValue)
                            if title == "Start" {
                                viewModel.isShowingStartDatePicker = false
                            } else {
                                viewModel.isShowingEndDatePicker = false
                            }
                        }
                        .foregroundStyle(AppColors.primaryText)
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(1.0 / 3.0)])
    }

}

/// Content-only view for the create flow: no property wrappers, so safe to create
/// inside fullScreenCover/sheet. Host passes viewModel; host’s @StateObject drives updates.
private struct EventCreateContentBody: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let authSession: AuthSessionStore
    let onDismiss: (() -> Void)?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                hostTopBar
                hostMediaTile
                hostFormFields
                hostOptionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(hostCreateEventBackground)
        // Cover image preprocessing is handled by CreateEventViewModel's Combine pipeline.
        .sheet(isPresented: viewModel.binding(\.isShowingStartDatePicker)) {
            hostDateTimePickerSheet(
                date: viewModel.binding(\.startDate),
                title: "Start",
                onDone: { viewModel.setStartDate($0) }
            )
        }
        .sheet(isPresented: viewModel.binding(\.isShowingEndDatePicker)) {
            hostDateTimePickerSheet(
                date: viewModel.binding(\.endDate),
                title: "End",
                onDone: { viewModel.setEndDate($0) }
            )
        }
        .sheet(isPresented: viewModel.binding(\.isShowingLocationSearch)) {
            LocationSearchView { displayName, addressLine, neighborhood, coordinate in
                viewModel.selectLocation(
                    displayName: displayName,
                    addressLine: addressLine,
                    neighborhood: neighborhood,
                    coordinate: coordinate
                )
                viewModel.isShowingLocationSearch = false
            }
        }
        .sheet(isPresented: viewModel.binding(\.isShowingDescriptionEditor)) {
            RichTextEditorView(text: viewModel.binding(\.descriptionText))
        }
        .sheet(isPresented: viewModel.binding(\.isShowingVisibilitySheet)) {
            EventVisibilitySheetContent(
                initialVisibility: viewModel.visibility,
                onConfirm: {
                    viewModel.setVisibility($0)
                    viewModel.isShowingVisibilitySheet = false
                },
                onDismiss: { viewModel.isShowingVisibilitySheet = false }
            )
            .presentationDetents([.height(420)])
        }
        .alert("Couldn't create event", isPresented: viewModel.binding(\.isCreateErrorPresented)) {
            Button("OK") {
                viewModel.createErrorMessage = nil
                viewModel.isCreateErrorPresented = false
            }
        } message: {
            if let msg = viewModel.createErrorMessage {
                Text(msg)
            }
        }
    }

    private var hostCreateEventBackground: some View {
        (Color(lightColor: Color(uiColor: .systemGray6), darkColor: Color.white.opacity(0.06)))
            .ignoresSafeArea()
    }

    private var hostTopBar: some View {
        HStack(spacing: 12) {
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .frame(width: 44, height: 44)
            .background(hostLiquidGlassCircleBackground)
            .clipShape(Circle())

            Spacer()
            Text("Create Event")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
            Spacer()
            Button {
                Task { await viewModel.createEvent() }
            } label: {
                Group {
                    if viewModel.isCreating {
                        ProgressView()
                            .tint(AppColors.primaryText)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(
                viewModel.isFormValid && !viewModel.isCreating
                    ? AppColors.primaryText : AppColors.tertiaryText
            )
            .opacity(viewModel.isFormValid && !viewModel.isCreating ? 1 : 0.5)
            .disabled(!viewModel.isFormValid || viewModel.isCreating)
            .frame(width: 44, height: 44)
            .background(hostLiquidGlassCircleBackground)
            .clipShape(Circle())
        }
        .padding(.vertical, 8)
        .alert("Couldn't create event", isPresented: viewModel.binding(\.isCreateErrorPresented)) {
            Button("OK") {
                viewModel.createErrorMessage = nil
                viewModel.isCreateErrorPresented = false
            }
        } message: {
            if let msg = viewModel.createErrorMessage {
                Text(msg)
            }
        }
    }

    @ViewBuilder
    private var hostLiquidGlassCircleBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular, in: .circle)
        } else {
            Color.clear.background(.ultraThinMaterial, in: Circle())
        }
    }

    private var hostMediaTile: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if viewModel.isProcessingCoverImage {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Processing...")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(width: side, height: side)
                    .background(AppColors.surface.opacity(0.5))
                } else if let data = viewModel.coverImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipped()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title)
                            .foregroundStyle(AppColors.tertiaryText)
                        Text("Upload image")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(width: side, height: side)
                    .background(AppColors.surface.opacity(0.5))
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        AppColors.divider,
                        style: viewModel.coverImageData == nil && !viewModel.isProcessingCoverImage
                            ? StrokeStyle(lineWidth: 2, dash: [8, 4])
                            : StrokeStyle(lineWidth: 1)
                    )
            }
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(
                    selection: viewModel.binding(\.coverPickerItem),
                    matching: .images
                ) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.primaryText)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessingCoverImage)
                .padding(12)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var hostFormFields: some View {
        VStack(spacing: 12) {
            _glassCard {
                TextField("Event Name", text: viewModel.binding(\.eventName))
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppColors.primaryText)
            }
            _glassCard {
                VStack(spacing: 0) {
                    Button {
                        viewModel.isShowingStartDatePicker = true
                    } label: {
                        HStack {
                            Text("Start")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                            Spacer()
                            Text(EventDateFormatter.startDateWithTime(viewModel.startDate))
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 16)
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .background(AppColors.divider)
                    Button {
                        viewModel.isShowingEndDatePicker = true
                    } label: {
                        HStack {
                            Text("End")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                            Spacer()
                            Text(EventDateFormatter.timeOnly(viewModel.endDate))
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 16)
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
            _glassCard {
                Button {
                    viewModel.isShowingLocationSearch = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(AppColors.tertiaryText)
                        Text(viewModel.selectedLocation?.displayName ?? "Choose Location")
                            .font(.subheadline)
                            .foregroundStyle(
                                viewModel.selectedLocation != nil
                                    ? AppColors.primaryText : AppColors.secondaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            _glassCard {
                Button {
                    viewModel.isShowingDescriptionEditor = true
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(AppColors.tertiaryText)
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.descriptionText.isEmpty {
                                Text("Add Description")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.secondaryText)
                            } else {
                                Text(hostTruncatedDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.primaryText)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var hostTruncatedDescription: String {
        let t = viewModel.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 80 { return t }
        return String(t.prefix(80)) + "…"
    }

    private var hostOptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OPTIONS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
            _glassCard {
                Button {
                    viewModel.isShowingVisibilitySheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "eye")
                            .foregroundStyle(AppColors.tertiaryText)
                        Text("Visibility")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(viewModel.visibility == .public ? "Public" : "Private")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func hostDateTimePickerSheet(
        date: Binding<Date>,
        title: String,
        onDone: @escaping (Date) -> Void
    ) -> some View {
        NavigationStack {
            MinuteIntervalDatePicker(date: date)
                .frame(maxWidth: .infinity)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            if title == "Start" {
                                viewModel.isShowingStartDatePicker = false
                            } else {
                                viewModel.isShowingEndDatePicker = false
                            }
                        }
                        .foregroundStyle(AppColors.primaryText)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onDone(date.wrappedValue)
                            if title == "Start" {
                                viewModel.isShowingStartDatePicker = false
                            } else {
                                viewModel.isShowingEndDatePicker = false
                            }
                        }
                        .foregroundStyle(AppColors.primaryText)
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(1.0 / 3.0)])
    }

}

/// Host used when presenting the create flow in fullScreenCover. Owns the view model;
/// body shows EventCreateContentBody (no property wrappers) so creation is safe.
@MainActor
struct EventCreateSheetHost: View {
    let authSession: AuthSessionStore
    let eventRepository: any EventRepository
    let categoryRepository: any CategoryRepository
    let eventImageUploadService: any EventImageUploadService
    let rsvpRepository: any RsvpRepository
    let onCreated: (Event) -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel: CreateEventViewModel

    init(
        authSession: AuthSessionStore,
        eventRepository: any EventRepository,
        categoryRepository: any CategoryRepository,
        eventImageUploadService: any EventImageUploadService,
        rsvpRepository: any RsvpRepository,
        onCreated: @escaping (Event) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.authSession = authSession
        self.eventRepository = eventRepository
        self.categoryRepository = categoryRepository
        self.eventImageUploadService = eventImageUploadService
        self.rsvpRepository = rsvpRepository
        self.onCreated = onCreated
        self.onDismiss = onDismiss
        _viewModel = StateObject(
            wrappedValue: CreateEventViewModel(
                authSession: authSession,
                eventRepository: eventRepository,
                categoryRepository: categoryRepository,
                eventImageUploadService: eventImageUploadService,
                rsvpRepository: rsvpRepository,
                onCreated: onCreated
            )
        )
    }

    var body: some View {
        EventCreateContentBody(
            viewModel: viewModel,
            authSession: authSession,
            onDismiss: onDismiss
        )
    }
}

#Preview {
    let previewAuth = AuthSessionStore(authRepository: PreviewAuthRepository())
    EventCreateView(
        viewModel: CreateEventViewModel(
            authSession: previewAuth,
            eventRepository: MockEventRepository(),
            categoryRepository: MockCategoryRepository(),
            eventImageUploadService: MockEventImageUploadService(),
            rsvpRepository: MockRsvpRepository(),
            onCreated: { _ in }
        ),
        authSession: previewAuth
    )
}
