import Foundation

/// Configuration for backend API endpoints
struct BackendConfig {
    // Production backend URL - deployed to Vercel
    static let baseURL = "https://keyco-backend-2jy3tiubw-benrobinsoncc-gmailcoms-projects.vercel.app"
    
    /// Full URL for the rewrite endpoint
    static var rewriteURL: URL? {
        return URL(string: "\(baseURL)/api/rewrite")
    }
    
    /// Full URL for the chat endpoint
    static var chatURL: URL? {
        return URL(string: "\(baseURL)/api/chat")
    }
}

