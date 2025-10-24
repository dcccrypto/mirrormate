import AVFoundation
import UIKit

final class CameraViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureMovieFileOutput()
    private var audioInput: AVCaptureDeviceInput?
    private let previewLayer = AVCaptureVideoPreviewLayer()
    
    // Dedicated queue for session management (Apple recommendation)
    private let sessionQueue = DispatchQueue(label: "com.mirrormate.camera.session", qos: .userInitiated)

    private var isConfigured = false
    var onRecordingFinished: ((URL?, Error?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        AppLog.info("📹 CameraViewController: viewDidLoad", category: .capture)
        view.backgroundColor = .black
        
        // Configure preview layer
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // CRITICAL: Add sublayer immediately
        view.layer.insertSublayer(previewLayer, at: 0)
        AppLog.info("📹 Preview layer added to view hierarchy", category: .capture)
        AppLog.info("📹 View bounds: \(view.bounds)", category: .capture)
        AppLog.info("📹 Preview layer frame: \(previewLayer.frame)", category: .capture)
        
        // Add observers to catch WHY session isn't starting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError,
            object: captureSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted,
            object: captureSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded,
            object: captureSession
        )
    }
    
    @objc private func sessionRuntimeError(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        AppLog.error("❌❌❌ AVCaptureSession RUNTIME ERROR: \(error.localizedDescription)", category: .capture)
        AppLog.error("Error code: \(error.code.rawValue)", category: .capture)
        
        if error.code == .mediaServicesWereReset {
            AppLog.info("Media services reset, restarting session...", category: .capture)
            sessionQueue.async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    @objc private func sessionWasInterrupted(notification: Notification) {
        if let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? AVCaptureSession.InterruptionReason {
            AppLog.warning("⚠️ Session interrupted: \(reason.rawValue)", category: .capture)
        }
    }
    
    @objc private func sessionInterruptionEnded(notification: Notification) {
        AppLog.info("Session interruption ended", category: .capture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppLog.debug("📹 viewDidLayoutSubviews called", category: .capture)
        previewLayer.frame = view.bounds
        
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
                AppLog.debug("📹 Video orientation set to portrait", category: .capture)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppLog.info("📹 CameraViewController: viewDidAppear", category: .capture)
        AppLog.info("📹 View is visible: \(!view.isHidden), Alpha: \(view.alpha)", category: .capture)
        AppLog.info("📹 Preview layer session: \(previewLayer.session != nil ? "connected" : "NOT connected")", category: .capture)
    }

    func configureIfNeeded() async throws {
        guard !isConfigured else { 
            AppLog.info("Camera already configured", category: .capture)
            return 
        }
        
        // CRITICAL: Configure audio session FIRST on main thread
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            AppLog.info("✓ Audio session configured and activated", category: .capture)
        } catch {
            AppLog.error("Failed to configure audio session: \(error)", category: .capture)
            throw error
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                AppLog.info("Configuring capture session on dedicated queue...", category: .capture)

                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = .high

                let front = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                guard let device = front ?? back else {
                    AppLog.error("No camera device found", category: .capture)
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "No camera device"]))
                    return
                }

                do {
                    let videoInput = try AVCaptureDeviceInput(device: device)
                    guard self.captureSession.canAddInput(videoInput) else {
                        AppLog.error("Cannot add video input to session", category: .capture)
                        self.captureSession.commitConfiguration()
                        continuation.resume(throwing: NSError(domain: "Camera", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"]))
                        return
                    }
                    self.captureSession.addInput(videoInput)
                    AppLog.info("✓ Video input added (camera: \(device.position == .front ? "front" : "back"))", category: .capture)
                } catch {
                    AppLog.error("Failed to create video input", category: .capture)
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: NSError(domain: "Camera", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create video input"]))
                    return
                }

                if let mic = AVCaptureDevice.default(for: .audio) {
                    if let micInput = try? AVCaptureDeviceInput(device: mic), self.captureSession.canAddInput(micInput) {
                        self.captureSession.addInput(micInput)
                        self.audioInput = micInput
                        AppLog.info("✓ Audio input added", category: .capture)
                    } else {
                        AppLog.warning("Could not add audio input", category: .capture)
                    }
                }

                guard self.captureSession.canAddOutput(self.videoOutput) else {
                    AppLog.error("Cannot add video output to session", category: .capture)
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: NSError(domain: "Camera", code: -4, userInfo: [NSLocalizedDescriptionKey: "Cannot add video output"]))
                    return
                }
                self.captureSession.addOutput(self.videoOutput)
                AppLog.info("✓ Video output added", category: .capture)

                self.captureSession.commitConfiguration()

                DispatchQueue.main.async {
                    self.previewLayer.session = self.captureSession
                    AppLog.info("✓ Preview layer connected to session", category: .capture)
                    self.isConfigured = true
                    AppLog.info("✓ Camera configuration complete", category: .capture)
                    continuation.resume()
                }
            }
        }
    }

    func startRunning() {
        // MUST run on dedicated session queue (Apple requirement)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.captureSession.isRunning else {
                AppLog.info("Session already running", category: .capture)
                return
            }
            
            AppLog.info("═══ Attempting to start session ═══", category: .capture)
            AppLog.info("Session inputs: \(self.captureSession.inputs.count)", category: .capture)
            AppLog.info("Session outputs: \(self.captureSession.outputs.count)", category: .capture)
            AppLog.info("Session preset: \(self.captureSession.sessionPreset.rawValue)", category: .capture)
            AppLog.info("Session is interrupted: \(self.captureSession.isInterrupted)", category: .capture)
            
            // Check if session can actually run
            if !self.captureSession.canSetSessionPreset(.high) {
                AppLog.warning("Cannot set .high preset!", category: .capture)
            }
            
            AppLog.info("Calling captureSession.startRunning()...", category: .capture)
            self.captureSession.startRunning()
            
            // Verify it started IMMEDIATELY
            let isRunningSync = self.captureSession.isRunning
            AppLog.info("isRunning (immediately after): \(isRunningSync)", category: .capture)
            
            // Wait and check again
            Thread.sleep(forTimeInterval: 0.5)
            let isRunningAfterDelay = self.captureSession.isRunning
            AppLog.info("isRunning (after 0.5s): \(isRunningAfterDelay)", category: .capture)
            
            if !isRunningAfterDelay {
                AppLog.error("❌❌❌ Session FAILED to start!", category: .capture)
                AppLog.error("This means AVFoundation is refusing to start the session.", category: .capture)
                AppLog.error("Possible causes:", category: .capture)
                AppLog.error("  1. Another app is using the camera", category: .capture)
                AppLog.error("  2. Camera is being used by system (FaceTime, Screen Recording)", category: .capture)
                AppLog.error("  3. Media services crashed or need reset", category: .capture)
                AppLog.error("  4. Device is in low power mode blocking camera", category: .capture)
            } else {
                AppLog.info("✅ Session started successfully!", category: .capture)
            }
        }
    }

    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    func startRecording(to url: URL, maxDuration: CMTime?) {
        AppLog.info("📹 startRecording called", category: .capture)
        AppLog.info("📹 Output URL: \(url.path)", category: .capture)
        
        // CRITICAL: Ensure session is running
        guard captureSession.isRunning else {
            AppLog.error("📹 ❌ Capture session NOT running! Cannot record!", category: .capture)
            return
        }
        
        // CRITICAL: Check if already recording
        guard !videoOutput.isRecording else {
            AppLog.warning("📹 ⚠️ Already recording, ignoring duplicate call", category: .capture)
            return
        }
        
        // Validate URL
        AppLog.info("📹 URL is file URL: \(url.isFileURL)", category: .capture)
        
        // Ensure parent directory exists
        let parentDir = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            do {
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                AppLog.info("📹 Created parent directory", category: .capture)
            } catch {
                AppLog.error("📹 ❌ Failed to create directory: \(error)", category: .capture)
                return
            }
        }
        
        // Delete file if it already exists (AVFoundation requires this)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                AppLog.info("📹 Removed existing file at path", category: .capture)
            } catch {
                AppLog.error("📹 ❌ Failed to remove existing file: \(error)", category: .capture)
                return
            }
        }
        
        // Get video connection
        guard let connection = videoOutput.connection(with: .video) else {
            AppLog.error("📹 ❌ NO VIDEO CONNECTION! Cannot record!", category: .capture)
            return
        }
        
        AppLog.info("📹 Video connection exists, active: \(connection.isActive), enabled: \(connection.isEnabled)", category: .capture)
        
        // Set orientation
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            AppLog.info("📹 Video orientation set to portrait", category: .capture)
        }
        
        // Set max duration if provided
        if let max = maxDuration { 
            videoOutput.maxRecordedDuration = max 
            AppLog.info("📹 Max duration set: \(max.seconds)s", category: .capture)
        } else {
            videoOutput.maxRecordedDuration = .invalid
        }
        
        // Start recording on session queue (same queue as session management)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            AppLog.info("📹 Calling videoOutput.startRecording on session queue...", category: .capture)
            self.videoOutput.startRecording(to: url, recordingDelegate: self)
            
            // Verify it started
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AppLog.info("📹 videoOutput.isRecording (after 0.5s): \(self.videoOutput.isRecording)", category: .capture)
                if !self.videoOutput.isRecording {
                    AppLog.error("📹 ❌ Recording did NOT start! This is an AVFoundation failure.", category: .capture)
                    AppLog.error("📹 ❌ Possible causes: disk space, permissions, or session interruption", category: .capture)
                    
                    // Try to trigger callback manually so UI isn't stuck
                    DispatchQueue.main.async {
                        self.onRecordingFinished?(url, NSError(domain: "CameraError", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Recording failed to start. Check disk space and permissions."
                        ]))
                    }
                }
            }
        }
    }

    func stopRecording() {
        AppLog.info("📹 stopRecording called", category: .capture)
        AppLog.info("📹 videoOutput.isRecording: \(videoOutput.isRecording)", category: .capture)
        
        if videoOutput.isRecording { 
            AppLog.info("📹 Calling videoOutput.stopRecording()...", category: .capture)
            videoOutput.stopRecording() 
        } else {
            AppLog.warning("📹 ⚠️ Not currently recording, nothing to stop", category: .capture)
        }
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        AppLog.info("📹 ✓ Recording STARTED to: \(fileURL.lastPathComponent)", category: .capture)
        AppLog.info("📹 File path: \(fileURL.path)", category: .capture)
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        AppLog.info("📹 ✓ Recording FINISHED", category: .capture)
        AppLog.info("📹 Output URL: \(outputFileURL.path)", category: .capture)
        AppLog.info("📹 Error: \(error?.localizedDescription ?? "none")", category: .capture)
        
        // Check if file exists
        let fileExists = FileManager.default.fileExists(atPath: outputFileURL.path)
        AppLog.info("📹 File exists: \(fileExists)", category: .capture)
        
        if fileExists {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: outputFileURL.path)
                let fileSize = attrs[.size] as? NSNumber
                AppLog.info("📹 File size: \(fileSize?.intValue ?? 0) bytes", category: .capture)
            } catch {
                AppLog.error("📹 Could not get file attributes: \(error)", category: .capture)
            }
        }
        
        AppLog.info("📹 Calling onRecordingFinished callback...", category: .capture)
        onRecordingFinished?(outputFileURL, error)
        AppLog.info("📹 Callback invoked", category: .capture)
    }
}


