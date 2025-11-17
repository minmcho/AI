//
//  ImageUtils.swift
//  NutriVision AI
//
//  Image processing utilities
//

import UIKit
import SwiftUI

struct ImageUtils {

    // MARK: - Image Compression

    static func compress(_ image: UIImage, quality: CGFloat = 0.7) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }

    static func compressToMaxSize(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxSizeKB * 1024, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        return imageData
    }

    // MARK: - Image Resizing

    static func resize(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    static func resizeToMaxDimension(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage? {
        let size = image.size
        let ratio = max(size.width, size.height) / maxDimension

        if ratio <= 1.0 {
            return image
        }

        let newSize = CGSize(
            width: size.width / ratio,
            height: size.height / ratio
        )

        return resize(image, to: newSize)
    }

    // MARK: - Base64 Conversion

    static func toBase64(_ image: UIImage, quality: CGFloat = 0.8) -> String? {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            return nil
        }
        return imageData.base64EncodedString()
    }

    static func fromBase64(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
    }

    // MARK: - Data URL

    static func toDataURL(_ image: UIImage, quality: CGFloat = 0.8) -> String? {
        guard let base64 = toBase64(image, quality: quality) else {
            return nil
        }
        return "data:image/jpeg;base64,\(base64)"
    }

    // MARK: - Image Cropping

    static func crop(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    static func cropToSquare(_ image: UIImage) -> UIImage? {
        let size = image.size
        let smallerDimension = min(size.width, size.height)

        let x = (size.width - smallerDimension) / 2
        let y = (size.height - smallerDimension) / 2

        let cropRect = CGRect(x: x, y: y, width: smallerDimension, height: smallerDimension)
        return crop(image, to: cropRect)
    }

    // MARK: - Image Orientation

    static func fixOrientation(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Thumbnail Generation

    static func generateThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        return resize(image, to: size)
    }

    // MARK: - Image Quality Check

    static func estimateQuality(_ image: UIImage) -> ImageQuality {
        let size = image.size
        let pixelCount = size.width * size.height

        if pixelCount < 640 * 480 {
            return .low
        } else if pixelCount < 1920 * 1080 {
            return .medium
        } else {
            return .high
        }
    }

    enum ImageQuality {
        case low, medium, high
    }

    // MARK: - Color Analysis

    static func dominantColor(_ image: UIImage) -> UIColor? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var red: Int = 0
        var green: Int = 0
        var blue: Int = 0
        let sampleSize = min(100, pixelData.count / bytesPerPixel)

        for i in stride(from: 0, to: pixelData.count, by: pixelData.count / sampleSize) {
            red += Int(pixelData[i])
            green += Int(pixelData[i + 1])
            blue += Int(pixelData[i + 2])
        }

        let avgRed = CGFloat(red) / CGFloat(sampleSize) / 255.0
        let avgGreen = CGFloat(green) / CGFloat(sampleSize) / 255.0
        let avgBlue = CGFloat(blue) / CGFloat(sampleSize) / 255.0

        return UIColor(red: avgRed, green: avgGreen, blue: avgBlue, alpha: 1.0)
    }
}
