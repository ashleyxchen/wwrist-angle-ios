//
//  ContentView.swift
//  wrist_angle_watchOS Watch App
//
//  Created by Ashley Chen on 2025-11-20.
//

import SwiftUI
import CoreMotion
import WatchConnectivity

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        VStack(spacing: 15) {
            Text("IMU Logger")
                .font(.headline)
                .foregroundColor(.blue)
            
            Button(action: {
                if motionManager.isRecording {
                    motionManager.stopRecording()
                } else {
                    motionManager.startRecording()
                }
            }) {
                VStack {
                    Image(systemName: motionManager.isRecording ? "stop.circle.fill" : "play.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(motionManager.isRecording ? .red : .green)
                    
                    Text(motionManager.isRecording ? "Stop" : "Start")
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if motionManager.isRecording {
                VStack(spacing: 5) {
                    Text("Recording...")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text("\(motionManager.sampleCount) samples")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Connection status
            HStack {
                Circle()
                    .fill(motionManager.isConnectedToPhone ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(motionManager.isConnectedToPhone ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
