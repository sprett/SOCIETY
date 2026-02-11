//
//  EventCreateView.swift
//  SOCIETY
//

import MapKit
import PhotosUI
import SwiftUI
import UIKit

// #region agent log
private func _dbg(_ msg: String, loc: String, hid: String) {
    let logPath = "/Users/dinoh/Documents/personal/code/society/SOCIETY/.cursor/debug.log"
    let ts = Int(Date().timeIntervalSince1970 * 1000)
    let line =
        "{\"location\":\"\(loc)\",\"message\":\"\(msg)\",\"timestamp\":\(ts),\"sessionId\":\"debug-session\",\"hypothesisId\":\"\(hid)\"}\n"
    guard let d = line.data(using: .utf8) else { return }
    let url = URL(fileURLWithPath: logPath)
    if !FileManager.default.fileExists(atPath: logPath) {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: logPath, contents: nil, attributes: nil)
    }
    if let h = try? FileHandle(forWritingTo: url) {
        h.seekToEndOfFile()
        h.write(d)
        try? h.close()
    }
}
// #endregion

private func _glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
}

/// Wheel date/time picker with time restricted to 15-minute intervals (date unchanged).
private struct MinuteIntervalDatePicker: UIViewRepresentable {
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
                CategoryPickerSheet(
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

private struct CategoryPickerSheet: View {
    let categories: [EventCategory]
    @Binding var selectedCategory: EventCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(categories) { category in
                Button {
                    selectedCategory = category
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.iconIdentifier)
                            .font(.system(size: 18))
                            .foregroundStyle(category.accentColor)
                            .frame(width: 28)
                        Text(category.name)
                            .font(.system(size: 17))
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(category.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}

/// Event Visibility sheet content matching the Luma-style design: icon, title, intro, Public/Private options, Confirm.
private struct EventVisibilitySheetContent: View {
    let initialVisibility: EventVisibility
    let onConfirm: (EventVisibility) -> Void
    let onDismiss: () -> Void

    @State private var selectedVisibility: EventVisibility

    init(
        initialVisibility: EventVisibility, onConfirm: @escaping (EventVisibility) -> Void,
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
                // Header: icon, title, close
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
                    .background(visibilitySheetLiquidGlassCircle)
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

                // Options
                VStack(spacing: 0) {
                    visibilityRow(
                        title: "Public",
                        description:
                            "Shown on SOCIETY events feed. Eligible to be featured.",
                        isSelected: selectedVisibility == .public
                    ) {
                        selectedVisibility = .public
                    }
                    Divider()
                        .background(AppColors.divider)
                    visibilityRow(
                        title: "Private",
                        description:
                            "Only people invited or with the link can register.",
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
        .background(visibilitySheetLiquidGlassBackground)
        .ignoresSafeArea(edges: .all)
    }

    @ViewBuilder
    private var visibilitySheetLiquidGlassCircle: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular, in: .circle)
        } else {
            Color.clear.background(.ultraThinMaterial, in: Circle())
        }
    }

    @ViewBuilder
    private var visibilitySheetLiquidGlassBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(
                .regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            Color.clear.background(
                .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
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
        .onChange(of: viewModel.coverPickerItem) { _, newItem in
            Task {
                await loadCoverImage(from: newItem)
            }
        }
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
                if let data = viewModel.coverImageData, let uiImage = UIImage(data: data) {
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
                        style: viewModel.coverImageData == nil
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

    private func loadCoverImage(from item: PhotosPickerItem?) async {
        guard let item = item else {
            viewModel.coverImageData = nil
            return
        }
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else {
            viewModel.coverPickerItem = nil
            viewModel.coverImageData = nil
            return
        }
        viewModel.coverImageData = data
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
        .onChange(of: viewModel.coverPickerItem) { _, newItem in
            Task {
                await hostLoadCoverImage(from: newItem)
            }
        }
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
                if let data = viewModel.coverImageData, let uiImage = UIImage(data: data) {
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
                        style: viewModel.coverImageData == nil
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

    private func hostLoadCoverImage(from item: PhotosPickerItem?) async {
        guard let item = item else {
            viewModel.coverImageData = nil
            return
        }
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else {
            viewModel.coverPickerItem = nil
            viewModel.coverImageData = nil
            return
        }
        viewModel.coverImageData = data
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
