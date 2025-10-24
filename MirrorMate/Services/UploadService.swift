import Foundation
import Supabase

final class UploadService {
    static let shared = UploadService()
    private init() {}

    func uploadFileSigned(fileURL: URL, path: String, token: String) async throws {
        let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.intValue ?? 0
        let sizeMB = Double(size) / 1_000_000.0
        
        AppLog.info("→ Starting signed upload", category: .upload)
        AppLog.info("  Path: \(path)", category: .upload)
        AppLog.info("  Size: \(String(format: "%.2f", sizeMB)) MB (\(size) bytes)", category: .upload)
        AppLog.info("  Token: \(token.prefix(20))...", category: .upload)
        
        let startTime = Date()
        
        do {
            // Respect desired content type based on file extension
            let contentType = (fileURL.pathExtension.lowercased() == "mp4") ? "video/mp4" : "video/quicktime"
            try await SupabaseService.shared.client.storage
                .from("videos")
                .uploadToSignedURL(path, token: token, fileURL: fileURL, options: FileOptions(contentType: contentType))
            
            let duration = Date().timeIntervalSince(startTime)
            let speedMBps = sizeMB / duration
            
            AppLog.info("✓ Upload completed successfully", category: .upload)
            AppLog.info("  Duration: \(String(format: "%.2f", duration))s", category: .upload)
            AppLog.info("  Speed: \(String(format: "%.2f", speedMBps)) MB/s", category: .upload)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            AppLog.error("✗ Upload failed after \(String(format: "%.2f", duration))s", category: .upload)
            AppLog.error("  Error: \(error.localizedDescription)", category: .upload)
            
            if let nsError = error as NSError? {
                AppLog.error("  Domain: \(nsError.domain), Code: \(nsError.code)", category: .upload)
                if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                    AppLog.error("  Underlying: \(underlying.domain) \(underlying.code)", category: .upload)
                }
            }
            throw error
        }
    }

    func uploadFileDirect(fileURL: URL, path: String) async throws {
        let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.intValue ?? 0
        let sizeMB = Double(size) / 1_000_000.0
        
        AppLog.info("→ Starting direct upload (fallback)", category: .upload)
        AppLog.info("  Path: \(path)", category: .upload)
        AppLog.info("  Size: \(String(format: "%.2f", sizeMB)) MB", category: .upload)
        
        let startTime = Date()
        
        do {
            let contentType = (fileURL.pathExtension.lowercased() == "mp4") ? "video/mp4" : "video/quicktime"
            try await SupabaseService.shared.client.storage
                .from("videos")
                .upload(path, fileURL: fileURL, options: FileOptions(contentType: contentType, upsert: true))
            
            let duration = Date().timeIntervalSince(startTime)
            AppLog.info("✓ Direct upload succeeded in \(String(format: "%.2f", duration))s", category: .upload)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            AppLog.error("✗ Direct upload failed after \(String(format: "%.2f", duration))s: \(error)", category: .upload)
            throw error
        }
    }
}


