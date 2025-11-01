import Foundation

/// Configuration for backend API endpoints
struct BackendConfig {
    // Production backend URL - deployed to Vercel
    // Using main domain which always points to latest deployment
    static let baseURL = "https://keyco-backend.vercel.app"
    
    /// Full URL for the rewrite endpoint
    static var rewriteURL: URL? {
        return URL(string: "\(baseURL)/api/rewrite")
    }
    
    /// Full URL for the chat endpoint
    static var chatURL: URL? {
        return URL(string: "\(baseURL)/api/chat")
    }
}

