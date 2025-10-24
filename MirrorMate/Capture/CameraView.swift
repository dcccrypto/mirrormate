import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var isRecording: Bool
    let outputURL: URL
    let maxDurationSeconds: Double?
    var onFinished: (URL?, Error?) -> Void = { _, _ in }

    func makeUIViewController(context: Context) -> CameraViewController {
        AppLog.info("📹 CameraView: Creating view controller", category: .capture)
        let vc = CameraViewController()
        
        // Set the callback
        vc.onRecordingFinished = { url, err in
            AppLog.info("📹 CameraView: Recording finished callback triggered", category: .capture)
            AppLog.info("📹 URL: \(url?.path ?? "nil"), Error: \(err?.localizedDescription ?? "nil")", category: .capture)
            onFinished(url, err)
        }
        
        // Configure camera asynchronously
        Task { @MainActor in
            AppLog.info("📹 CameraView: Requesting permissions...", category: .capture)
            let granted = await Permissions.requestCameraAndMic()
            
            if granted {
                AppLog.info("📹 CameraView: Permissions granted, configuring camera...", category: .capture)
                do {
                    try await vc.configureIfNeeded()
                    AppLog.info("📹 CameraView: Configuration complete, starting session...", category: .capture)
                    vc.startRunning()
                    
                    // Give session time to start
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    AppLog.info("📹 CameraView: Camera should now be visible", category: .capture)
                } catch {
                    AppLog.error("📹 CameraView: Configuration failed: \(error)", category: .capture)
                }
            } else {
                AppLog.error("📹 CameraView: Permissions denied", category: .capture)
            }
        }
        
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        AppLog.debug("📹 CameraView: updateUIViewController called, isRecording=\(isRecording)", category: .capture)
        
        if isRecording {
            if !context.coordinator.recordingStarted {
                context.coordinator.recordingStarted = true
                AppLog.info("📹 CameraView: Starting recording to: \(outputURL.lastPathComponent)", category: .capture)
                
                let max: CMTime? = maxDurationSeconds.map { CMTime(seconds: $0, preferredTimescale: 600) }
                uiViewController.startRecording(to: outputURL, maxDuration: max)
                
                AppLog.info("📹 CameraView: Recording command sent", category: .capture)
            }
        } else {
            if context.coordinator.recordingStarted {
                context.coordinator.recordingStarted = false
                AppLog.info("📹 CameraView: Stopping recording...", category: .capture)
                uiViewController.stopRecording()
                AppLog.info("📹 CameraView: Stop recording command sent", category: .capture)
            }
        }
    }

    func makeCoordinator() -> Coordinator { 
        AppLog.info("📹 CameraView: Creating coordinator", category: .capture)
        return Coordinator() 
    }

    final class Coordinator {
        var recordingStarted = false
    }
}


