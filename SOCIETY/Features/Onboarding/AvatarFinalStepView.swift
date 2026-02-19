//
//  AvatarFinalStepView.swift
//  SOCIETY
//

import PhotosUI
import SwiftUI

/// Protocol for completing the avatar step without storing a closure in the view body
/// (avoids swift_retain crashes when the closure is invoked from async context).
@MainActor
protocol AvatarStepCompletionHandler: AnyObject {
    func completeSetup(avatarURL: String?) async
}

struct AvatarFinalStepView: View {
    @StateObject private var viewModel: AvatarFinalStepViewModel
    private let completion: Completion

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showErrorAlert = false
    @State private var diceRotation: Double = 0
    @State private var diceScale: CGFloat = 1

    enum Completion {
        case closure((_ avatarURL: String) async throws -> Void)
        case handler(AvatarStepCompletionHandler)
    }

    init(
        userId: UUID,
        avatarService: any AvatarService,
        completionHandler: AvatarStepCompletionHandler
    ) {
        _viewModel = StateObject(
            wrappedValue: AvatarFinalStepViewModel(userId: userId, avatarService: avatarService)
        )
        self.completion = .handler(completionHandler)
    }

    init(
        userId: UUID,
        avatarService: any AvatarService,
        onContinue: @escaping (_ avatarURL: String) async throws -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: AvatarFinalStepViewModel(userId: userId, avatarService: avatarService)
        )
        self.completion = .closure(onContinue)
    }

    var body: some View {
        Group {
            if viewModel.isGenerating && viewModel.displayImage == nil && viewModel.generationError == nil {
                loadingState
            } else if viewModel.displayImage == nil {
                retryState
            } else {
                content
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.displayImage != nil)
        .task {
            await viewModel.loadInitialAvatar()
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await viewModel.handleSelectedPhoto(item) }
        }
        .onChange(of: viewModel.error) { _, newValue in
            showErrorAlert = newValue != nil
        }
        .alert("Avatar Error", isPresented: $showErrorAlert) {
            Button("Retry") {
                Task { await continueTapped() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "Something went wrong.")
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Generating your avatar...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var retryState: some View {
        VStack(spacing: 14) {
            Text("We couldn’t generate your avatar")
                .font(.system(size: 20, weight: .semibold))
            if let generationError = viewModel.generationError {
                Text(generationError)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Try again") {
                Task { await viewModel.loadInitialAvatar() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var content: some View {
        VStack(spacing: 0) {
            Text("Pick an avatar")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AppColors.primaryText)
                .padding(.top, 18)
                .padding(.bottom, 10)

            Text("Keep this one or choose your own")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.secondaryText)
                .padding(.bottom, 24)

            Spacer(minLength: 28)

            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                avatarPreview
            }
            .buttonStyle(.plain)

            randomizeButton
                .padding(.top, 20)

            Spacer()

            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Choose from library")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)

            Button {
                Task { await continueTapped() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isUploading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.canContinue ? Color.primary : Color(.systemGray4),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .disabled(!viewModel.canContinue)
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private var avatarPreview: some View {
        Group {
            if let image = viewModel.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 176, height: 176)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        .scaleEffect(viewModel.isRandomizing ? 0.98 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.displayImage)
    }

    private var randomizeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            animateDiceRoll()
            Task { await viewModel.randomizeAvatar() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "die.face.5")
                    .font(.system(size: 17, weight: .semibold))
                    .rotationEffect(.degrees(diceRotation))
                    .scaleEffect(diceScale)

                Text("Randomize")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(.systemGray6))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isRandomizing || viewModel.isUploading)
    }

    private func animateDiceRoll() {
        withAnimation(.easeInOut(duration: 0.45)) {
            diceRotation += 360
            diceScale = 1.12
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.55).delay(0.1)) {
            diceScale = 1
        }
    }

    private func continueTapped() async {
        guard viewModel.canContinue else { return }
        do {
            let avatarURL = try await viewModel.uploadSelectionAndPersist()
            switch completion {
            case .closure(let action):
                try await action(avatarURL)
            case .handler(let handler):
                await handler.completeSetup(avatarURL: avatarURL)
            }
        } catch {
            viewModel.error = error.localizedDescription
        }
    }
}

#Preview {
    AvatarFinalStepView(
        userId: UUID(),
        avatarService: MockAvatarService(),
        onContinue: { _ in }
    )
}
