import Foundation
import Network

class ConnectivityManager {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitor")
    
    var isConnected: Bool = false
    var onConnectivityChanged: ((Bool) -> Void)?
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            
            if self?.isConnected != connected {
                self?.isConnected = connected
                self?.onConnectivityChanged?(connected)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}