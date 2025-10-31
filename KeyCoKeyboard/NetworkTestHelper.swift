import Foundation

/// Helper to test network connectivity from keyboard extension
class NetworkTestHelper {
    static func testConnectivity() {
        NSLog("[NetworkTest] Testing basic connectivity...")
        
        // Test 1: Simple URL resolution
        if let url = URL(string: "https://www.apple.com") {
            let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
                if let error = error {
                    NSLog("[NetworkTest] ❌ Apple.com failed: \(error.localizedDescription)")
                } else {
                    NSLog("[NetworkTest] ✅ Apple.com works - network access is OK")
                }
            }
            task.resume()
        }
        
        // Test 2: Backend URL resolution
        if let backendURL = URL(string: BackendConfig.baseURL) {
            NSLog("[NetworkTest] Backend URL created: \(backendURL.absoluteString)")
            NSLog("[NetworkTest] Host: \(backendURL.host ?? "nil")")
            NSLog("[NetworkTest] Scheme: \(backendURL.scheme ?? "nil")")
        } else {
            NSLog("[NetworkTest] ❌ Failed to create backend URL!")
        }
    }
}

