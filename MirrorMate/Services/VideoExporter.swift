import Foundation
import AVFoundation

final class VideoExporter {
    static let shared = VideoExporter()
    private init() {}

    /// Remuxes a QuickTime `.mov` file to a proper MP4 container without re-encoding when possible.
    /// Falls back to medium quality export if passthrough fails. Ensures the resulting file size is below a specified limit if provided.
    func exportToMP4(inputURL: URL, maxSizeMB: Double? = nil) async throws -> URL {
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        // Clean up any existing file at destination
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        // First try a fast remux using passthrough (no re-encode)
        do {
            try await export(inputURL: inputURL, outputURL: outputURL, presetName: AVAssetExportPresetPassthrough, fileType: .mp4)
        } catch {
            // Fallback to medium quality re-encode
            try await export(inputURL: inputURL, outputURL: outputURL, presetName: AVAssetExportPresetMediumQuality, fileType: .mp4)
        }

        if let maxSizeMB = maxSizeMB {
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? NSNumber)?.doubleValue ?? 0
            let sizeMB = fileSize / 1_000_000.0
            if sizeMB > maxSizeMB {
                // Re-export with low quality to reduce size
                let smallerURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp4")

                if FileManager.default.fileExists(atPath: smallerURL.path) {
                    try? FileManager.default.removeItem(at: smallerURL)
                }

                try await export(inputURL: inputURL, outputURL: smallerURL, presetName: AVAssetExportPresetLowQuality, fileType: .mp4)
                return smallerURL
            }
        }

        return outputURL
    }

    private func export(inputURL: URL, outputURL: URL, presetName: String, fileType: AVFileType) async throws {
        let asset = AVURLAsset(url: inputURL)
        guard let session = AVAssetExportSession(asset: asset, presetName: presetName) else {
            throw NSError(domain: "VideoExporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"])
        }
        session.outputURL = outputURL
        session.outputFileType = fileType
        session.shouldOptimizeForNetworkUse = true

        // Use modern API on iOS 18+, fallback to legacy API for older versions
        if #available(iOS 18.0, *) {
            // Modern API: direct async/await
            try await session.export(to: outputURL, as: fileType)
        } else {
            // Legacy API with continuation
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                session.exportAsynchronously {
                    switch session.status {
                    case .completed:
                        continuation.resume(returning: ())
                    case .failed, .cancelled:
                        let err = session.error ?? NSError(domain: "VideoExporter", code: -2, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
                        continuation.resume(throwing: err)
                    default:
                        // Treat unexpected states as failure
                        let err = NSError(domain: "VideoExporter", code: -3, userInfo: [NSLocalizedDescriptionKey: "Export did not complete"])
                        continuation.resume(throwing: err)
                    }
                }
            }
        }
    }
}


