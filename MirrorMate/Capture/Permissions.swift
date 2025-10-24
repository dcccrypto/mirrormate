import AVFoundation
import Foundation
import UIKit

enum Permissions {
    enum State { case authorized, denied, notDetermined }

    static func cameraStatus() -> State {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    static func micStatus() -> State {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .authorized
        case .denied: return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    static func requestCameraAndMic() async -> Bool {
        let cameraGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVCaptureDevice.requestAccess(for: .video) { granted in cont.resume(returning: granted) }
        }
        let micGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in cont.resume(returning: granted) }
        }
        return cameraGranted && micGranted
    }

    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}


