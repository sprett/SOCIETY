//
//  ImageProcessor.swift
//  SOCIETY
//
//  On-device image preprocessing: center-crop to square, resize, JPEG encode.
//  All heavy work runs off the main thread via async so callers can await safely.
//

import CoreGraphics
import UIKit

@MainActor
struct ImageProcessor {

    // MARK: - Configuration

    struct Config: Sendable {
        var eventSize: Int = 1024
        var eventJPEGQuality: CGFloat = 0.75
        var profileSize: Int = 512
        var profileJPEGQuality: CGFloat = 0.70
        var thumbSize: Int = 256
        var thumbJPEGQuality: CGFloat = 0.60
        /// Whether to produce a 100×100 thumb alongside the main event image.
        var produceEventThumb: Bool = true

        static let `default` = Config()
    }

    let config: Config

    nonisolated init(config: Config = .default) {
        self.config = config
    }

    // MARK: - Primitive operations (synchronous, testable)

    /// Center-crops the image to a 1:1 square using the shorter dimension.
    func centerCropSquare(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let side = min(width, height)

        let originX = (width - side) / 2.0
        let originY = (height - side) / 2.0
        let cropRect = CGRect(x: originX, y: originY, width: side, height: side)

        guard let cropped = cgImage.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Resizes the image to the exact target size using high-quality interpolation.
    func resize(image: UIImage, to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1  // absolute pixel size, not points
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Encodes the image as JPEG data at the given compression quality.
    func encodeJPEG(image: UIImage, quality: CGFloat) -> Data {
        image.jpegData(compressionQuality: quality) ?? Data()
    }

    // MARK: - High-level pipelines (async)

    /// Processes raw image data for an event cover:
    /// - Decodes to UIImage
    /// - Center-crops to square
    /// - Resizes to 512×512 → JPEG
    /// - Optionally resizes to 100×100 thumb → JPEG
    func processEventImage(from data: Data) async throws -> (main512: Data, thumb100: Data?) {
        guard let original = UIImage(data: data) else {
            throw ImageProcessorError.decodingFailed
        }

        let squared = centerCropSquare(original)

        let eventSide = CGFloat(config.eventSize)
        let main = resize(image: squared, to: CGSize(width: eventSide, height: eventSide))
        let mainData = encodeJPEG(image: main, quality: config.eventJPEGQuality)

        guard !mainData.isEmpty else {
            throw ImageProcessorError.encodingFailed
        }

        var thumbData: Data? = nil
        if config.produceEventThumb {
            let thumbSide = CGFloat(config.thumbSize)
            let thumb = resize(image: squared, to: CGSize(width: thumbSide, height: thumbSide))
            let encoded = encodeJPEG(image: thumb, quality: config.thumbJPEGQuality)
            if !encoded.isEmpty {
                thumbData = encoded
            }
        }

        return (main512: mainData, thumb100: thumbData)
    }

    /// Processes raw image data for a profile avatar:
    /// - Decodes to UIImage
    /// - Center-crops to square
    /// - Resizes to 100×100 → JPEG
    func processProfileImage(from data: Data) async throws -> Data {
        guard let original = UIImage(data: data) else {
            throw ImageProcessorError.decodingFailed
        }

        let squared = centerCropSquare(original)

        let side = CGFloat(config.profileSize)
        let avatar = resize(image: squared, to: CGSize(width: side, height: side))
        let avatarData = encodeJPEG(image: avatar, quality: config.profileJPEGQuality)

        guard !avatarData.isEmpty else {
            throw ImageProcessorError.encodingFailed
        }

        return avatarData
    }
}

// MARK: - Errors

enum ImageProcessorError: LocalizedError {
    case decodingFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .decodingFailed:
            return "Unable to decode image data."
        case .encodingFailed:
            return "Unable to encode processed image."
        }
    }
}
