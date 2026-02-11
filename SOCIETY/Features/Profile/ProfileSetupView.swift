//
//  ProfileSetupView.swift
//  SOCIETY
//
//  Stepped profile setup flow:
//  location → notifications → name → birthday → contact → photo
//

import CoreLocation
import PhotosUI
import SwiftUI
import UserNotifications

struct ProfileSetupView: View {
    @StateObject private var viewModel: ProfileSetupViewModel

    init(
        authSession: AuthSessionStore,
        profileRepository: any ProfileRepository,
        categoryRepository: any CategoryRepository,
        profileImageUploadService: any ProfileImageUploadService
    ) {
        _viewModel = StateObject(
            wrappedValue: ProfileSetupViewModel(
                authSession: authSession,
                profileRepository: profileRepository,
                categoryRepository: categoryRepository,
                profileImageUploadService: profileImageUploadService
            ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 24)

            // Step content with slide transitions
            ZStack {
                switch viewModel.currentStep {
                case .interests:
                    ProfileInterestsStepView(viewModel: viewModel)
                        .transition(slideTransition)
                case .location:
                    ProfileLocationStepView(viewModel: viewModel)
                        .transition(slideTransition)
                case .notifications:
                    ProfileNotificationsStepView(viewModel: viewModel)
                        .transition(slideTransition)
                case .name:
                    ProfileNameStepView(viewModel: viewModel)
                        .transition(slideTransition)
                case .birthday:
                    ProfileBirthdayStepView(viewModel: viewModel)
                        .transition(slideTransition)
                case .contact:
                    ProfileContactStepView(viewModel: viewModel)
                        .transition(slideTransition)
                case .photo:
                    ProfilePhotoStepView(viewModel: viewModel)
                        .transition(slideTransition)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.currentStep)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                    .background(AppColors.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                Capsule()
                    .fill(AppColors.primaryText)
                    .frame(
                        width: geo.size.width * viewModel.progress,
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Interests Step

private struct ProfileInterestsStepView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    @Environment(\.colorScheme) private var colorScheme

    // Adaptive columns: flexible pills that wrap
    private let columns = [
        GridItem(.adaptive(minimum: 130, maximum: 200), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("What interests you?")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(AppColors.primaryText)

                Text("Select at least 3 categories to personalize your feed")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)

            if viewModel.isLoadingCategories {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                // Category grid
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(viewModel.categories) { category in
                            InterestPillView(
                                category: category,
                                isSelected: viewModel.selectedInterestIds.contains(category.id),
                                colorScheme: colorScheme
                            ) {
                                viewModel.toggleInterest(category.id)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }

            // Select all / Deselect all
            if !viewModel.categories.isEmpty {
                Button {
                    if viewModel.allInterestsSelected {
                        viewModel.deselectAllInterests()
                    } else {
                        viewModel.selectAllInterests()
                    }
                } label: {
                    Text(viewModel.allInterestsSelected ? "Deselect all" : "Select all")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .padding(.bottom, 4)
            }

            // Selection count hint
            if !viewModel.canContinueInterests && !viewModel.categories.isEmpty {
                Text("\(viewModel.selectedInterestIds.count) of 3 selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.tertiaryText)
                    .padding(.bottom, 8)
            }

            // Continue button
            ProfileContinueButton(
                enabled: viewModel.canContinueInterests,
                isLoading: viewModel.isSaving
            ) {
                Task {
                    await viewModel.saveInterests()
                    viewModel.goToNextStep()
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Interest Pill

private struct InterestPillView: View {
    let category: EventCategory
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: category.iconIdentifier)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? category.accentColor : Color(.systemGray))

                Text(category.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? selectedTextColor : Color(.systemGray))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? selectedBackground : unselectedBackground,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        isSelected ? category.accentColor.opacity(0.4) : Color(.systemGray4),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var selectedTextColor: Color {
        colorScheme == .dark ? .white : AppColors.primaryText
    }

    private var selectedBackground: Color {
        category.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.12)
    }

    private var unselectedBackground: Color {
        Color(.systemGray6)
    }
}

// MARK: - Location Permission Step

private struct ProfileLocationStepView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.onboardingAccent)
                .padding(.bottom, 32)

            Text("Enable location")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AppColors.primaryText)
                .padding(.bottom, 12)

            Text("Find events near you")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .padding(.bottom, 16)

            Text(
                "We use your location to show events\nhappening nearby and help you discover\nnew experiences in your area."
            )
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(AppColors.tertiaryText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                ProfileActionButton(
                    title: "Turn on location",
                    style: .primary
                ) {
                    locationManager.requestLocationPermission()
                    // Small delay to allow the system prompt to appear / be dismissed,
                    // then advance regardless of the user's choice.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.goToNextStep()
                    }
                }

                ProfileActionButton(
                    title: "Not now",
                    style: .secondary
                ) {
                    viewModel.goToNextStep()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 40)
    }
}

// MARK: - Notifications Permission Step

private struct ProfileNotificationsStepView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.onboardingAccent)
                .padding(.bottom, 32)

            Text("Stay updated")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AppColors.primaryText)
                .padding(.bottom, 12)

            Text("Get reminders and updates for\nevents you care about")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)

            Text(
                "We'll send you notifications about event\nreminders, friend activity, and important\nupdates from hosts."
            )
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(AppColors.tertiaryText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                ProfileActionButton(
                    title: "Turn on notifications",
                    style: .primary
                ) {
                    Task {
                        await viewModel.requestNotificationPermission()
                        viewModel.goToNextStep()
                    }
                }

                ProfileActionButton(
                    title: "Not now",
                    style: .secondary
                ) {
                    viewModel.goToNextStep()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 40)
    }
}

// MARK: - Name Step

private struct ProfileNameStepView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    @FocusState private var focusedField: NameField?

    private enum NameField {
        case first, last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What's your name?")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AppColors.primaryText)
                .padding(.bottom, 12)

            Text("This is how you'll appear to other users")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .padding(.bottom, 32)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("First name")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.leading, 4)

                    TextField("First name", text: $viewModel.firstName)
                        .font(.system(size: 17))
                        .textInputAutocapitalization(.words)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .focused($focusedField, equals: .first)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last name")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.leading, 4)

                    TextField("Last name", text: $viewModel.lastName)
                        .font(.system(size: 17))
                        .textInputAutocapitalization(.words)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .focused($focusedField, equals: .last)
                }
            }

            Spacer()

            if let msg = viewModel.errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(AppColors.danger)
                    .padding(.bottom, 8)
            }

            ProfileContinueButton(
                enabled: viewModel.canContinueName,
                isLoading: viewModel.isSaving
            ) {
                viewModel.goToNextStep()
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 40)
        .onAppear {
            focusedField = .first
        }
    }
}

// MARK: - Birthday Step

private struct ProfileBirthdayStepView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("When's your birthday?")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AppColors.primaryText)
                .padding(.bottom, 12)

            Text("You must be 18 or older to use SOCIETY")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .padding(.bottom, 32)

            DatePicker(
                "",
                selection: Binding(
                    get: {
                        viewModel.birthday ?? Calendar.current.date(
                            byAdding: .year, value: -25, to: Date()) ?? Date()
                    },
                    set: { viewModel.birthday = $0 }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Spacer()

            if let msg = viewModel.errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(AppColors.danger)
                    .padding(.bottom, 8)
            }

            ProfileContinueButton(
                enabled: viewModel.canContinueBirthday,
                isLoading: viewModel.isSaving
            ) {
                viewModel.goToNextStep()
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 40)
    }
}

// MARK: - Contact Step

private struct ProfileContactStepView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    @FocusState private var focusedField: ContactField?
    @State private var showCountryPicker = false

    private enum ContactField {
        case email, phone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Contact info")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AppColors.primaryText)
                .padding(.bottom, 12)

            Text("We'll use this to send you event updates")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 16) {
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.leading, 4)

                    TextField("your@email.com", text: $viewModel.email)
                        .font(.system(size: 17))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .focused($focusedField, equals: .email)
                }

                // Phone with country code dropdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.leading, 4)

                    HStack(spacing: 0) {
                        // Country code button
                        Button {
                            showCountryPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Text(viewModel.selectedCountry.flag)
                                    .font(.system(size: 20))
                                Text(viewModel.selectedCountry.dialingCode)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppColors.primaryText)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                        }

                        // Divider
                        Rectangle()
                            .fill(AppColors.divider)
                            .frame(width: 1, height: 24)

                        // Phone number input
                        TextField("Phone number", text: $viewModel.phoneLocal)
                            .font(.system(size: 17))
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .focused($focusedField, equals: .phone)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                }
            }

            Spacer()

            if let msg = viewModel.errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(AppColors.danger)
                    .padding(.bottom, 8)
            }

            ProfileContinueButton(
                enabled: viewModel.canContinueContact,
                isLoading: viewModel.isSaving
            ) {
                viewModel.goToNextStep()
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 40)
        .onAppear {
            focusedField = .email
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selectedCountry: $viewModel.selectedCountry)
        }
    }
}

// MARK: - Country Picker Sheet

private struct CountryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountry: CountryPhoneCode
    @State private var searchText = ""

    private var filteredCountries: [CountryPhoneCode] {
        if searchText.isEmpty {
            return CountryPhoneCode.all
        }
        let query = searchText.lowercased()
        return CountryPhoneCode.all.filter {
            $0.name.lowercased().contains(query)
                || $0.dialingCode.contains(query)
                || $0.id.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button {
                    selectedCountry = country
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.system(size: 24))
                        Text(country.name)
                            .font(.system(size: 17))
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(country.dialingCode)
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.secondaryText)
                        if country.id == selectedCountry.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.onboardingAccent)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Country Code")
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

// MARK: - Photo Step

private struct ProfilePhotoStepView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("Add a photo")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AppColors.primaryText)
                .padding(.bottom, 12)

            Text("Help friends recognize you")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .padding(.bottom, 48)

            // Photo upload area
            ZStack(alignment: .bottomTrailing) {
                if let imageData = viewModel.selectedImageData,
                    let uiImage = UIImage(data: imageData)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                } else if let url = viewModel.profileImageURL {
                    UserAvatarView(imageURL: url, size: 160)
                } else {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 160, height: 160)
                        .overlay {
                            Image(systemName: "camera")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                }

                PhotosPicker(
                    selection: $viewModel.selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 40, height: 40)
                        .background(AppColors.elevatedSurface, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(AppColors.divider, lineWidth: 1)
                        }
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.bottom, 24)

            // Choose from library text button
            PhotosPicker(
                selection: $viewModel.selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Choose from library")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
            .disabled(viewModel.isLoading)

            Spacer()

            if let msg = viewModel.errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(AppColors.danger)
                    .padding(.bottom, 8)
            }

            // Buttons
            VStack(spacing: 12) {
                ProfileContinueButton(
                    enabled: !viewModel.isSaving,
                    isLoading: viewModel.isSaving
                ) {
                    Task { await viewModel.completeSetup() }
                }

                Button {
                    Task { await viewModel.completeSetup() }
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .disabled(viewModel.isSaving)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 40)
    }
}

// MARK: - Shared Continue Button

private struct ProfileContinueButton: View {
    let enabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(enabled ? Color(.systemBackground) : AppColors.tertiaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                enabled ? AppColors.primaryText : Color(.systemGray5),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .disabled(!enabled || isLoading)
        .buttonStyle(ProfileScaleOnPressStyle())
    }
}

// MARK: - Shared Action Button (Primary / Secondary)

private struct ProfileActionButton: View {
    enum Style { case primary, secondary }

    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    backgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ProfileScaleOnPressStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return Color(.systemBackground)
        case .secondary: return AppColors.secondaryText
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return AppColors.primaryText
        case .secondary: return .clear
        }
    }
}

private struct ProfileScaleOnPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileSetupView(
            authSession: AuthSessionStore(authRepository: PreviewAuthRepository()),
            profileRepository: MockProfileRepository(),
            categoryRepository: MockCategoryRepository(),
            profileImageUploadService: MockProfileImageUploadService()
        )
    }
}
