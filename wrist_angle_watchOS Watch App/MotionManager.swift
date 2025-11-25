import Foundation
import CoreMotion
import WatchConnectivity
import Combine

class MotionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isRecording = false
    @Published var isConnectedToPhone = false
    @Published var sampleCount = 0
    
    private let motionManager = CMMotionManager()
    private let session = WCSession.default
    private var startTime: Date?
    
    override init() {
        super.init()
        setupWatchConnectivity()
        setupMotionManager()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        // Set update interval to 100Hz (0.01 seconds)
        motionManager.deviceMotionUpdateInterval = 0.01
    }
    
    func startRecording() {
        guard !isRecording else { return }
        guard motionManager.isDeviceMotionAvailable else { return }
        
        startTime = Date()
        sampleCount = 0
        isRecording = true
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            self.sampleCount += 1
            self.sendMotionData(motion)
        }
        
        print("Started recording motion data")
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        motionManager.stopDeviceMotionUpdates()
        isRecording = false
        
        print("Stopped recording motion data. Total samples: \(sampleCount)")
    }
    
    private func sendMotionData(_ motion: CMDeviceMotion) {
        guard session.isReachable else { return }
        
        let timestamp = Date().timeIntervalSince1970 * 1_000_000 // microseconds
        let secondsElapsed = startTime?.timeIntervalSinceNow ?? 0
        
        let data: [String: Any] = [
            "source": "WATCH",
            "timestamp": timestamp,
            "seconds_elapsed": abs(secondsElapsed),
            "rotationRateX": motion.rotationRate.x,
            "rotationRateY": motion.rotationRate.y,
            "rotationRateZ": motion.rotationRate.z,
            "gravityX": motion.gravity.x,
            "gravityY": motion.gravity.y,
            "gravityZ": motion.gravity.z,
            "accelerationX": motion.userAcceleration.x,
            "accelerationY": motion.userAcceleration.y,
            "accelerationZ": motion.userAcceleration.z,
            "quaternionW": motion.attitude.quaternion.w,
            "quaternionX": motion.attitude.quaternion.x,
            "quaternionY": motion.attitude.quaternion.y,
            "quaternionZ": motion.attitude.quaternion.z,
            "pitch": motion.attitude.pitch,
            "roll": motion.attitude.roll,
            "yaw": motion.attitude.yaw
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Error sending motion data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnectedToPhone = (activationState == .activated && session.isReachable)
        }
        
        if let error = error {
            print("Watch session activation error: \(error.localizedDescription)")
        } else {
            print("Watch session activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle messages from iOS app if needed
        print("Watch received message: \(message)")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnectedToPhone = session.isReachable
        }
        print("Watch session reachability changed: \(session.isReachable)")
    }
}
