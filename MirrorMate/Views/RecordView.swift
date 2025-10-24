import SwiftUI
import AVFoundation
import PostHog

struct RecordView: View {
    @State private var isRecording = false
    @State private var outputURL: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.mov")
    @State private var elapsed: Double = 0
    private let maxDuration: Double = 60
    @StateObject private var stripe = StripeManager.shared
    @State private var createdSessionId: String? = nil
    @State private var showControls = true

    var body: some View {
        ZStack {
            // Camera Feed
            if permissionsGranted {
                CameraView(isRecording: $isRecording, outputURL: outputURL, maxDurationSeconds: nil) { url, err in
                    AppLog.info("Recording finished callback. url=\(String(describing: url)) err=\(String(describing: err))", category: .capture)
                    
                    // CRITICAL: Update state on main thread
                    DispatchQueue.main.async {
                        guard err == nil, let fileURL = url else {
                            AppLog.error("Recording error: \(err?.localizedDescription ?? "unknown")", category: .capture)
                            errorMessage = "Recording failed. Please try again."
                            HapticFeedback.error.trigger()
                            return
                        }
                        
                        AppLog.info("✓ Recording saved to: \(fileURL.path)", category: .capture)
                        AppLog.info("✓ File exists: \(FileManager.default.fileExists(atPath: fileURL.path))", category: .capture)
                        
                        // Set the recorded URL - this should trigger upload button to appear
                        lastRecordedURL = fileURL
                        HapticFeedback.success.trigger()
                        
                        AppLog.info("✓ lastRecordedURL set, upload button should appear", category: .capture)
                    }
                }
                .ignoresSafeArea()
            } else {
                // Permission Required Screen
                VStack(spacing: AppTheme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.primary.opacity(0.1))
                            .frame(width: 120, height: 120)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Camera & Microphone Access")
                            .font(AppTheme.Fonts.title2())
                            .foregroundColor(AppTheme.Colors.contrast)
                        Text("MirrorMate needs access to analyze your reflection.")
                            .font(AppTheme.Fonts.body())
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    
                    Button(action: { 
                        Permissions.openSettings()
                        HapticFeedback.light.trigger()
                    }) {
                        Text("Open Settings")
                            .font(AppTheme.Fonts.bodyMedium())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(AppTheme.Colors.primaryGradient)
                            .cornerRadius(AppTheme.CornerRadius.md)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    .bounceButton()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Colors.background)
            }

            // Camera Controls Overlay
            if permissionsGranted && showControls {
                VStack {
                    // Top Controls
                    HStack {
                        // Premium Badge
                        if stripe.isPremium {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.accent)
                                Text("Premium")
                                    .font(AppTheme.Fonts.caption())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.Colors.accent.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                        
                        // Timer Display
                        if isRecording {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(AppTheme.Colors.error)
                                    .frame(width: 8, height: 8)
                                    .pulse()
                                
                                Text(formattedElapsed())
                                    .font(AppTheme.Fonts.bodyMedium())
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                            )
                        }
                    }
                    .padding(AppTheme.Spacing.lg)

                    Spacer()

                    // Gaze Guide Overlay
                    GazeOverlayView()
                        .padding(.bottom, 180)
                        .opacity(isRecording ? 1 : 0.6)
                        .animation(AppTheme.Animation.smooth, value: isRecording)

                    Spacer()

                    // Bottom Controls
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Record Button
                        Button(action: {
                            toggleRecording()
                            HapticFeedback.medium.trigger()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? AppTheme.Colors.error : AppTheme.Colors.success)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: (isRecording ? AppTheme.Colors.error : AppTheme.Colors.success).opacity(0.5), radius: 20, x: 0, y: 10)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 88, height: 88)
                                
                                if isRecording {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                }
                            }
                        }
                        .disabled(!permissionsGranted)
                        .opacity(permissionsGranted ? 1 : 0.5)
                        .scaleEffect(isRecording ? 0.95 : 1.0)
                        .animation(AppTheme.Animation.spring, value: isRecording)
                        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
                        .accessibilityHint(isRecording ? "Double tap to stop your video recording" : "Double tap to start recording your practice video")

                        // Status Text
                        Text(isRecording ? "Tap to stop" : "Tap to record")
                            .font(AppTheme.Fonts.subheadline())
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                            )

                        // Upload Button or Loading State
                        if isUploading {
                            VStack(spacing: AppTheme.Spacing.sm) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                
                                Text(uploadStatusMessage)
                                    .font(AppTheme.Fonts.bodyMedium())
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.lg)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .transition(.scale.combined(with: .opacity))
                        } else if let readyURL = lastRecordedURL, !isRecording {
                            Button(action: {
                                AppLog.info("User initiated upload for file: \(readyURL.lastPathComponent)", category: .ui)
                                Task { await uploadAndAnalyze(fileURL: readyURL) }
                                HapticFeedback.medium.trigger()
                            }) {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Upload & Analyze")
                                        .font(AppTheme.Fonts.headline())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(AppTheme.Colors.primaryGradient)
                                .cornerRadius(AppTheme.CornerRadius.lg)
                                .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                            }
                            .disabled(isUploading)
                            .bounceButton()
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                .transition(.opacity)
            }
            
            // Error Message
            if let error = errorMessage {
                VStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text(error)
                                .font(AppTheme.Fonts.subheadline())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        Button(action: {
                            withAnimation {
                                errorMessage = nil
                            }
                            HapticFeedback.light.trigger()
                        }) {
                            Text("Dismiss")
                                .font(AppTheme.Fonts.subheadline())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.sm)
                                .background(.white.opacity(0.2))
                                .cornerRadius(AppTheme.CornerRadius.sm)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.error)
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .shadow(radius: 10)
                    .padding(AppTheme.Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    HapticFeedback.error.trigger()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            AppLog.info("RecordView appeared", category: .ui)
            try? FileManager.default.removeItem(at: outputURL)
            outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mov")
            startTimer()
            
            // Refresh premium status when view appears
            Task {
                await stripe.checkPremiumStatus()
            }
            
            // Check permissions
            switch (Permissions.cameraStatus(), Permissions.micStatus()) {
            case (.authorized, .authorized): 
                permissionsGranted = true
            case (.notDetermined, _), (_, .notDetermined):
                Task { permissionsGranted = await Permissions.requestCameraAndMic() }
            default: 
                permissionsGranted = false
            }
        }
        .onDisappear { 
            stopTimer()
            AppLog.info("RecordView disappeared", category: .ui)
        }
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigate) {
            if let sessionId = createdSessionId {
                ProcessingView(sessionId: sessionId)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @State private var navigate = false
    @State private var showPaywall = false
    @State private var permissionsGranted = false
    @State private var errorMessage: String? = nil
    @State private var lastRecordedURL: URL? = nil
    @State private var isUploading = false
    @State private var uploadStatusMessage = "Preparing..."
    
    private func toggleRecording() {
        AppLog.info("toggleRecording called, isRecording=\(isRecording)", category: .capture)
        
        // If currently recording, just stop
        if isRecording {
            isRecording = false
            AppLog.info("Stopping recording...", category: .capture)
            
            // Track recording completion
            PostHogSDK.shared.capture("recording_completed", properties: [
                "duration": elapsed,
                "is_premium": stripe.isPremium
            ])
            return
        }
        
        // Starting a NEW recording - clear previous recording and check quota
        lastRecordedURL = nil
        AppLog.info("Cleared previous recording URL", category: .capture)
        
        Task { @MainActor in
            let canAnalyze = await QuotaService.shared.canAnalyzeToday(isPremium: stripe.isPremium)
            if !canAnalyze {
                AppLog.warning("Daily quota exceeded, showing paywall", category: .ui)
                showPaywall = true
                HapticFeedback.warning.trigger()
                return
            }
            
            // Quota available - start recording
            AppLog.info("Starting recording...", category: .capture)
            isRecording = true
            
            // Track recording start
            PostHogSDK.shared.capture("recording_started", properties: [
                "is_premium": stripe.isPremium
            ])
        }
    }

    @State private var timer: Timer? = nil
    private func uploadAndAnalyze(fileURL: URL) async {
        isUploading = true
        uploadStatusMessage = "Preparing upload..."
        HapticFeedback.light.trigger()
        
        AppLog.info("═══ Starting Analysis Flow ═══", category: .analysis)
        AppLog.info("Video file: \(fileURL.lastPathComponent)", category: .capture)
        
        do {
            // Convert MOV to MP4 on-device to ensure OpenAI compatibility and correct MIME type
            uploadStatusMessage = "Converting to MP4..."
            AppLog.info("Preprocessing: converting to MP4 before upload", category: .analysis)
            let mp4URL = try await VideoExporter.shared.exportToMP4(inputURL: fileURL, maxSizeMB: 24.5)

            let mp4Size = (try? FileManager.default.attributesOfItem(atPath: mp4URL.path)[.size] as? NSNumber)?.intValue ?? 0
            let mp4MB = Double(mp4Size) / 1_000_000.0
            AppLog.info(String(format: "Converted MP4 size: %.2f MB", mp4MB), category: .analysis)
            
            // Track upload initiation
            PostHogSDK.shared.capture("upload_initiated", properties: [
                "file_size_mb": mp4MB,
                "is_premium": stripe.isPremium
            ])
            if mp4MB > 25.0 {
                throw NSError(domain: "Upload", code: -10, userInfo: [NSLocalizedDescriptionKey: "Video too large (>25MB). Please record a shorter clip."])
            }
            // Step 1: Initialize session
            let deviceId = DeviceIdentifier.get()
            uploadStatusMessage = "Creating session..."
            AppLog.info("Step 1/4: Creating session...", category: .analysis)
            let initResp = try await ApiClient.shared.initSession(maxDurationSec: Int(maxDuration), deviceId: deviceId)
            createdSessionId = initResp.sessionId
            
            // Step 2: Upload video
            uploadStatusMessage = "Uploading video..."
            AppLog.info("Step 2/4: Uploading video...", category: .analysis)
            if let path = initResp.uploadPath, let token = initResp.uploadToken {
                try await UploadService.shared.uploadFileSigned(fileURL: mp4URL, path: path, token: token)
            } else if let path = initResp.uploadPath {
                AppLog.warning("Token missing, attempting direct upload", category: .upload)
                try await UploadService.shared.uploadFileDirect(fileURL: mp4URL, path: path)
            } else {
                AppLog.critical("Missing uploadPath/token from init-session response", category: .analysis)
                throw URLError(.badServerResponse)
            }
            
            // Step 3: Finalize session
            uploadStatusMessage = "Finalizing..."
            AppLog.info("Step 3/4: Finalizing session...", category: .analysis)
            _ = try await ApiClient.shared.finalize(sessionId: initResp.sessionId)
            
            // Step 4: Mark quota and navigate
            uploadStatusMessage = "Starting analysis..."
            AppLog.info("Step 4/4: Session ready for analysis", category: .analysis)
            await QuotaService.shared.markUsedToday()
            AppLog.info("═══ Analysis Flow Complete ═══", category: .analysis)
            
            // Track upload and analysis completion
            PostHogSDK.shared.capture("upload_completed", properties: [
                "file_size_mb": mp4MB,
                "is_premium": stripe.isPremium
            ])
            PostHogSDK.shared.capture("analysis_started", properties: [
                "session_id": createdSessionId ?? "",
                "is_premium": stripe.isPremium
            ])
            
            HapticFeedback.success.trigger()
            isUploading = false
            
            // Navigate to ProcessingView
            navigate = true
        } catch let error as URLError {
            AppLog.error("Network error: \(error.localizedDescription) (code: \(error.code.rawValue))", category: .network)
            isUploading = false
            errorMessage = "Network error. Please check your connection and try again."
            HapticFeedback.error.trigger()
        } catch let error as NSError where error.domain == "Upload" && error.code == -10 {
            AppLog.error("Video size error: \(error.localizedDescription)", category: .analysis)
            isUploading = false
            errorMessage = "Video too large. Please record a shorter clip."
            HapticFeedback.error.trigger()
        } catch {
            AppLog.error("Unexpected error: \(error.localizedDescription)", category: .analysis)
            isUploading = false
            errorMessage = "Something went wrong. Please try again."
            HapticFeedback.error.trigger()
        }
    }
    private func startTimer() {
        elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            if isRecording { elapsed += 0.25 }
        }
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func formattedElapsed() -> String {
        let total = Int(elapsed)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}



