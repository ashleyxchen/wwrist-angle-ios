import SwiftUI

struct ContentView: View {
    @StateObject private var dataForwarder = WatchDataForwarder()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "applewatch.and.arrow.forward")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("IMU Data Forwarder")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Forwards Apple Watch motion data to your MacBook")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Connection Status
                VStack(spacing: 15) {
                    // Watch Connection
                    HStack {
                        Image(systemName: "applewatch")
                        Circle()
                            .fill(dataForwarder.isWatchConnected ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text(dataForwarder.isWatchConnected ? "Watch Connected" : "Watch Disconnected")
                            .foregroundColor(dataForwarder.isWatchConnected ? .primary : .red)
                    }
                    
                    // MacBook Connection
                    HStack {
                        Image(systemName: "laptopcomputer")
                        Circle()
                            .fill(dataForwarder.isMacBookConnected ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text(dataForwarder.isMacBookConnected ? "MacBook Connected" : "MacBook Disconnected")
                            .foregroundColor(dataForwarder.isMacBookConnected ? .primary : .red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Statistics
                VStack(spacing: 10) {
                    Text("Data Statistics")
                        .font(.headline)
                    
                    HStack {
                        VStack {
                            Text("\(dataForwarder.packetsForwarded)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Packets Sent")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text(String(format: "%.1f Hz", dataForwarder.dataRate))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Data Rate")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Instructions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Instructions:")
                        .font(.headline)
                    
                    Text("1. Make sure your MacBook is running the Python data collector")
                    Text("2. Ensure iPhone and MacBook are on the same WiFi network")
                    Text("3. Open the Watch app and start recording")
                    Text("4. Data will automatically forward to your MacBook")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("IMU Forwarder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
