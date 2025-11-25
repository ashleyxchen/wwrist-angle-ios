//
//  WatchDataForwarder.swift
//  wrist_angle_ios
//
//  Created by Ashley Chen on 2025-11-20.
//

import Foundation
import WatchConnectivity
import Network
import Combine

class WatchDataForwarder: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isWatchConnected = false
    @Published var isMacBookConnected = false
    @Published var packetsForwarded = 0
    @Published var dataRate: Double = 0.0
    
    private let session = WCSession.default
    private var udpConnection: NWConnection?
    private let macbookIP = "192.168.2.130" // UPDATE THIS TO YOUR MACBOOK'S IP
    private let udpPort: UInt16 = 8889
    
    private var lastPacketTime = Date()
    private var packetTimes: [Date] = []
    
    override init() {
        super.init()
        setupWatchConnectivity()
        setupUDPConnection()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    private func setupUDPConnection() {
        let host = NWEndpoint.Host(macbookIP)
        let port = NWEndpoint.Port(rawValue: udpPort)!
        
        udpConnection = NWConnection(host: host, port: port, using: .udp)
        
        udpConnection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isMacBookConnected = true
                    print("UDP connection to MacBook ready")
                case .failed(let error):
                    self?.isMacBookConnected = false
                    print("UDP connection failed: \(error)")
                case .cancelled:
                    self?.isMacBookConnected = false
                    print("UDP connection cancelled")
                default:
                    break
                }
            }
        }
        
        udpConnection?.start(queue: .global())
    }
    
    private func forwardToMacBook(_ data: [String: Any]) {
        guard let udpConnection = udpConnection, isMacBookConnected else {
            print("Cannot forward: UDP connection not ready")
            return
        }
        
        // Convert watch data to CSV format matching Arduino output
        let timestamp = data["timestamp"] as? Double ?? 0
        let secondsElapsed = data["seconds_elapsed"] as? Double ?? 0
        
        let csvLine = "WATCH," +
                     "\(Int(timestamp))," +
                     String(format: "%.8f", secondsElapsed) + "," +
                     String(format: "%.8f", data["rotationRateX"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["rotationRateY"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["rotationRateZ"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["gravityX"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["gravityY"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["gravityZ"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["accelerationX"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["accelerationY"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["accelerationZ"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["quaternionW"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["quaternionX"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["quaternionY"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["quaternionZ"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["pitch"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["roll"] as? Double ?? 0) + "," +
                     String(format: "%.8f", data["yaw"] as? Double ?? 0)
        
        let udpData = csvLine.data(using: .utf8)!
        
        udpConnection.send(content: udpData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("UDP send error: \(error)")
            } else {
                DispatchQueue.main.async {
                    self?.packetsForwarded += 1
                    self?.updateDataRate()
                }
            }
        })
    }
    
    private func updateDataRate() {
        let now = Date()
        packetTimes.append(now)
        
        // Keep only packets from last 5 seconds for rate calculation
        packetTimes = packetTimes.filter { now.timeIntervalSince($0) <= 5.0 }
        
        if packetTimes.count >= 2 {
            dataRate = Double(packetTimes.count) / 5.0
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = (activationState == .activated && session.isReachable)
        }
        
        if let error = error {
            print("iOS session activation error: \(error.localizedDescription)")
        } else {
            print("iOS session activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS session deactivated")
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("iOS received motion data from watch")
        forwardToMacBook(message)
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
        }
        print("iOS session reachability changed: \(session.isReachable)")
    }
}
