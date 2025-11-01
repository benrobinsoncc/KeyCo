import Foundation

/// Centralized API client with retry logic, exponential backoff, and circuit breaker
final class APIClient {
    
    // MARK: - Configuration
    
    private struct Config {
        static let maxRetries = 3
        static let baseRetryDelay: TimeInterval = 1.0
        static let jitterRange: TimeInterval = 0.3 // 30% jitter for randomization
        static let circuitBreakerThreshold = 3
        static let circuitBreakerCooldown: TimeInterval = 30.0
        static let circuitBreakerHalfOpenTimeout: TimeInterval = 10.0 // Try again after 10s in half-open
        static let requestTimeout: TimeInterval = 30.0
        static let networkCheckTimeout: TimeInterval = 5.0
        static let healthCheckTimeout: TimeInterval = 3.0
        static let maxRequestAge: TimeInterval = 300.0 // 5 minutes - deduplicate requests
    }
    
    // MARK: - Circuit Breaker State
    
    private enum CircuitBreakerState {
        case closed
        case open(openUntil: Date)
        case halfOpen(halfOpenUntil: Date)
        
        var openUntil: Date? {
            if case .open(let date) = self {
                return date
            }
            return nil
        }
    }
    
    private static var consecutiveFailures = 0
    private static var circuitBreakerState: CircuitBreakerState = .closed
    private static let circuitBreakerQueue = DispatchQueue(label: "com.keyco.apiclient.circuitbreaker")
    
    // MARK: - Request Deduplication
    
    private static var activeRequests: [String: Date] = [:]
    private static let requestDeduplicationQueue = DispatchQueue(label: "com.keyco.apiclient.deduplication")
    
    // MARK: - Request Types
    
    struct RewriteRequest {
        let text: String
        let tone: Float
        let length: Float
    }
    
    struct ChatRequest {
        let query: String
    }
    
    // MARK: - Response Types
    
    struct RewriteResponse {
        let text: String
    }
    
    struct ChatResponse {
        let text: String
    }
    
    // MARK: - Error Types
    
    enum APIError: LocalizedError {
        case networkError(String)
        case httpError(Int, String)
        case invalidResponse
        case invalidRequest
        case circuitBreakerOpen
        case timeout
        case noData
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "Connection issue: \(message)"
            case .httpError(let code, let message):
                // If message already contains retry info, use it directly
                if message.contains("Retried") {
                    return message
                }
                return APIError.userFriendlyMessage(for: code, details: message)
            case .invalidResponse:
                return "Invalid response from server. Please try again."
            case .invalidRequest:
                return "Invalid request. Please check your input."
            case .circuitBreakerOpen:
                return "Service is temporarily unavailable. Please try again in a moment."
            case .timeout:
                return "Request timed out. Please try again."
            case .noData:
                return "No response received from server."
            }
        }
        
        static func userFriendlyMessage(for statusCode: Int, details: String? = nil) -> String {
            switch statusCode {
            case 400:
                return "Invalid request. Please try again."
            case 401:
                return "Authentication failed. Please check configuration."
            case 403:
                return "Access denied. Please check permissions."
            case 404:
                return "Service not found. Please check configuration."
            case 429:
                return "Too many requests. Please wait a moment and try again."
            case 500, 502, 503:
                return "Service temporarily unavailable. Please try again."
            case 504:
                return "Request timed out. Please try again."
            default:
                return details ?? "HTTP Error \(statusCode). Please try again."
            }
        }
        
        var shouldRetry: Bool {
            switch self {
            case .networkError, .timeout:
                return true
            case .httpError(let code, _) where (500...599).contains(code):
                return true
            case .httpError(429, _):
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Rewrite Text API
    
    /// Rewrite text with tone and length parameters
    static func rewriteText(
        request: RewriteRequest,
        retryAttempt: Int = 0,
        onProgress: ((String) -> Void)? = nil,
        completion: @escaping (Result<RewriteResponse, APIError>) -> Void
    ) {
        // Check for duplicate requests (prevent spam)
        let requestKey = self.requestKey(for: request)
        if isDuplicateRequest(requestKey) {
            DispatchQueue.main.async {
                onProgress?("Request already in progress...")
            }
            return
        }
        
        // Check network connectivity before making request
        checkNetworkConnectivity { isConnected in
            guard isConnected else {
                DispatchQueue.main.async {
                    completion(.failure(.networkError("No internet connection. Please check your network settings.")))
                }
                return
            }
            
            // Continue with API call...
            self.performRewriteRequest(request: request, retryAttempt: retryAttempt, onProgress: onProgress, completion: completion)
        }
    }
    
    private static func performRewriteRequest(
        request: RewriteRequest,
        retryAttempt: Int,
        onProgress: ((String) -> Void)?,
        completion: @escaping (Result<RewriteResponse, APIError>) -> Void
    ) {
        // Check circuit breaker state
        let circuitState = getCircuitBreakerState()
        switch circuitState {
        case .open(let openUntil):
            let remaining = Int(openUntil.timeIntervalSinceNow)
            DispatchQueue.main.async {
                onProgress?("Service temporarily unavailable. Please wait \(remaining)s...")
            }
            DispatchQueue.main.async {
                completion(.failure(.circuitBreakerOpen))
            }
            return
            
        case .halfOpen:
            // In half-open state, check health before proceeding
            checkBackendHealth { isHealthy in
                if isHealthy {
                    // Backend is healthy, proceed with request
                    self.executeRewriteRequest(request: request, retryAttempt: retryAttempt, onProgress: onProgress, completion: completion)
                } else {
                    // Still unhealthy, back to open state
                    self.setCircuitBreakerState(.open(openUntil: Date().addingTimeInterval(Config.circuitBreakerCooldown)))
                    DispatchQueue.main.async {
                        onProgress?("Service temporarily unavailable. Please try again in a moment.")
                    }
                    DispatchQueue.main.async {
                        completion(.failure(.circuitBreakerOpen))
                    }
                }
            }
            return
            
        case .closed:
            // Circuit breaker is closed, proceed normally
            executeRewriteRequest(request: request, retryAttempt: retryAttempt, onProgress: onProgress, completion: completion)
        }
    }
    
    private static func executeRewriteRequest(
        request: RewriteRequest,
        retryAttempt: Int,
        onProgress: ((String) -> Void)?,
        completion: @escaping (Result<RewriteResponse, APIError>) -> Void
    ) {
        // Validate request
        guard !request.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(.invalidRequest))
            }
            return
        }
        
        guard request.tone >= 0 && request.tone <= 1 && request.length >= 0 && request.length <= 1 else {
            DispatchQueue.main.async {
                completion(.failure(.invalidRequest))
            }
            return
        }
        
        // Show retry status if retrying
        if retryAttempt > 0 {
            DispatchQueue.main.async {
                onProgress?("Retrying... (\(retryAttempt)/\(Config.maxRetries))")
            }
        }
        
        // Make API call
        guard let url = BackendConfig.rewriteURL else {
            DispatchQueue.main.async {
                completion(.failure(.invalidRequest))
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Config.requestTimeout
        
        let requestBody: [String: Any] = [
            "text": request.text,
            "tone": Double(request.tone),
            "length": Double(request.length)
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            DispatchQueue.main.async {
                completion(.failure(.invalidRequest))
            }
            return
        }
        
        urlRequest.httpBody = httpBody
        
        // Log request (sanitized)
        NSLog("[APIClient] Rewrite request - tone: \(request.tone), length: \(request.length), text length: \(request.text.count)")
        NSLog("[APIClient] Request URL: \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // Check for network errors
            if let error = error {
                let nsError = error as NSError
                
                // Check for cancellation (don't retry)
                if nsError.code == NSURLErrorCancelled {
                    DispatchQueue.main.async {
                        completion(.failure(.networkError("Request cancelled")))
                    }
                    return
                }
                
                // Check for timeout
                if nsError.code == NSURLErrorTimedOut {
                    handleFailure(error: .timeout, retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                    return
                }
                
                // Other network errors
                handleFailure(error: .networkError(error.localizedDescription), retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                return
            }
            
            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                handleFailure(error: .invalidResponse, retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                return
            }
            
            let statusCode = httpResponse.statusCode
            
            // Log response
            NSLog("[APIClient] Rewrite response - Status: \(statusCode)")
            
            // Log response headers and body for debugging
            if statusCode >= 400 {
                NSLog("[APIClient] Error response headers: \(httpResponse.allHeaderFields)")
                if let data = data, let errorBody = String(data: data, encoding: .utf8) {
                    NSLog("[APIClient] Error response body: \(errorBody)")
                }
            }
            
            // Handle non-200 status codes
            if statusCode < 200 || statusCode >= 300 {
                let errorMessage = extractErrorMessage(from: data)
                NSLog("[APIClient] HTTP Error \(statusCode): \(errorMessage)")
                let error = APIError.httpError(statusCode, errorMessage)
                
                // Check if we should retry
                if error.shouldRetry && retryAttempt < Config.maxRetries {
                    handleFailure(error: error, retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                    return
                }
                
                // Don't retry - report error
                recordFailure()
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Success - reset circuit breaker
            recordSuccess()
            
            // Parse response
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                // Check for error in response body
                if let errorMessage = json["error"] as? String {
                    let details = json["details"] as? String
                    let error = APIError.httpError(statusCode, details ?? errorMessage)
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                // Extract text
                guard let text = json["text"] as? String else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                NSLog("[APIClient] Rewrite success - Response length: \(trimmedText.count)")
                DispatchQueue.main.async {
                    completion(.success(RewriteResponse(text: trimmedText)))
                }
                
            } catch {
                NSLog("[APIClient] JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Chat Query API
    
    /// Query ChatGPT API
    static func chatQuery(
        request: ChatRequest,
        retryAttempt: Int = 0,
        onProgress: ((String) -> Void)? = nil,
        completion: @escaping (Result<ChatResponse, APIError>) -> Void
    ) {
        // Check for duplicate requests (prevent spam)
        let requestKey = self.requestKey(for: request)
        if isDuplicateRequest(requestKey) {
            DispatchQueue.main.async {
                onProgress?("Request already in progress...")
            }
            return
        }
        
        // Check network connectivity before making request
        checkNetworkConnectivity { isConnected in
            guard isConnected else {
                DispatchQueue.main.async {
                    completion(.failure(.networkError("No internet connection. Please check your network settings.")))
                }
                return
            }
            
            // Continue with API call...
            self.performChatRequest(request: request, retryAttempt: retryAttempt, onProgress: onProgress, completion: completion)
        }
    }
    
    private static func performChatRequest(
        request: ChatRequest,
        retryAttempt: Int,
        onProgress: ((String) -> Void)?,
        completion: @escaping (Result<ChatResponse, APIError>) -> Void
    ) {
        // Check circuit breaker state
        let circuitState = getCircuitBreakerState()
        switch circuitState {
        case .open(let openUntil):
            let remaining = Int(openUntil.timeIntervalSinceNow)
            DispatchQueue.main.async {
                onProgress?("Service temporarily unavailable. Please wait \(remaining)s...")
            }
            DispatchQueue.main.async {
                completion(.failure(.circuitBreakerOpen))
            }
            return
            
        case .halfOpen:
            // In half-open state, check health before proceeding
            checkBackendHealth { isHealthy in
                if isHealthy {
                    // Backend is healthy, proceed with request
                    self.executeChatRequest(request: request, retryAttempt: retryAttempt, onProgress: onProgress, completion: completion)
                } else {
                    // Still unhealthy, back to open state
                    self.setCircuitBreakerState(.open(openUntil: Date().addingTimeInterval(Config.circuitBreakerCooldown)))
                    DispatchQueue.main.async {
                        onProgress?("Service temporarily unavailable. Please try again in a moment.")
                    }
                    DispatchQueue.main.async {
                        completion(.failure(.circuitBreakerOpen))
                    }
                }
            }
            return
            
        case .closed:
            // Circuit breaker is closed, proceed normally
            executeChatRequest(request: request, retryAttempt: retryAttempt, onProgress: onProgress, completion: completion)
        }
    }
    
    private static func executeChatRequest(
        request: ChatRequest,
        retryAttempt: Int,
        onProgress: ((String) -> Void)?,
        completion: @escaping (Result<ChatResponse, APIError>) -> Void
    ) {
        // Validate request
        guard !request.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(.invalidRequest))
            }
            return
        }
        
        // Show retry status if retrying
        if retryAttempt > 0 {
            DispatchQueue.main.async {
                onProgress?("Retrying... (\(retryAttempt)/\(Config.maxRetries))")
            }
        }
        
        // Make API call
        guard let url = BackendConfig.chatURL else {
            DispatchQueue.main.async {
                completion(.failure(.invalidRequest))
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Config.requestTimeout
        
        let requestBody: [String: Any] = [
            "query": request.query
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            DispatchQueue.main.async {
                completion(.failure(.invalidRequest))
            }
            return
        }
        
        urlRequest.httpBody = httpBody
        
        // Log request (sanitized)
        NSLog("[APIClient] Chat request - query length: \(request.query.count)")
        NSLog("[APIClient] Request URL: \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // Check for network errors
            if let error = error {
                let nsError = error as NSError
                
                // Check for cancellation (don't retry)
                if nsError.code == NSURLErrorCancelled {
                    DispatchQueue.main.async {
                        completion(.failure(.networkError("Request cancelled")))
                    }
                    return
                }
                
                // Check for timeout
                if nsError.code == NSURLErrorTimedOut {
                    handleChatFailure(error: .timeout, retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                    return
                }
                
                // Other network errors
                handleChatFailure(error: .networkError(error.localizedDescription), retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                return
            }
            
            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                handleChatFailure(error: .invalidResponse, retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                return
            }
            
            let statusCode = httpResponse.statusCode
            
            // Log response
            NSLog("[APIClient] Chat response - Status: \(statusCode)")
            
            // Log response headers and body for debugging
            if statusCode >= 400 {
                NSLog("[APIClient] Error response headers: \(httpResponse.allHeaderFields)")
                if let data = data, let errorBody = String(data: data, encoding: .utf8) {
                    NSLog("[APIClient] Error response body: \(errorBody)")
                }
            }
            
            // Handle non-200 status codes
            if statusCode < 200 || statusCode >= 300 {
                let errorMessage = extractErrorMessage(from: data)
                NSLog("[APIClient] HTTP Error \(statusCode): \(errorMessage)")
                let error = APIError.httpError(statusCode, errorMessage)
                
                // Check if we should retry
                if error.shouldRetry && retryAttempt < Config.maxRetries {
                    handleChatFailure(error: error, retryAttempt: retryAttempt, request: request, onProgress: onProgress, completion: completion)
                    return
                }
                
                // Don't retry - report error
                recordFailure()
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Success - reset circuit breaker
            recordSuccess()
            
            // Parse response
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                // Check for error in response body
                if let errorMessage = json["error"] as? String {
                    let details = json["details"] as? String
                    let error = APIError.httpError(statusCode, details ?? errorMessage)
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                // Extract text
                guard let text = json["text"] as? String else {
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                NSLog("[APIClient] Chat success - Response length: \(trimmedText.count)")
                DispatchQueue.main.async {
                    completion(.success(ChatResponse(text: trimmedText)))
                }
                
            } catch {
                NSLog("[APIClient] JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Retry Logic
    
    private static func handleFailure(
        error: APIError,
        retryAttempt: Int,
        request: RewriteRequest,
        onProgress: ((String) -> Void)?,
        completion: @escaping (Result<RewriteResponse, APIError>) -> Void
    ) {
        // Check if we should retry
        guard error.shouldRetry && retryAttempt < Config.maxRetries else {
            recordFailure()
            // If we've exhausted retries, provide a more helpful error message
            let finalError: APIError
            if retryAttempt >= Config.maxRetries {
                // All retries exhausted - create enhanced error message
                switch error {
                case .httpError(let code, let details):
                    let baseMessage = APIError.userFriendlyMessage(for: code, details: details)
                    finalError = .httpError(code, "\(baseMessage) Retried \(Config.maxRetries) times without success.")
                case .timeout:
                    finalError = .networkError("Request timed out. Retried \(Config.maxRetries) times without success.")
                case .networkError(let message):
                    finalError = .networkError("\(message) Retried \(Config.maxRetries) times without success.")
                default:
                    finalError = error
                }
            } else {
                finalError = error
            }
            DispatchQueue.main.async {
                completion(.failure(finalError))
            }
            return
        }
        
        // Calculate exponential backoff delay: 1s, 2s, 4s (with jitter)
        let delay = calculateBackoffDelay(retryAttempt: retryAttempt)
        let nextAttempt = retryAttempt + 1
        
        NSLog("[APIClient] Retrying rewrite request after \(String(format: "%.2f", delay))s (attempt \(nextAttempt)/\(Config.maxRetries))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            rewriteText(request: request, retryAttempt: nextAttempt, onProgress: onProgress, completion: completion)
        }
    }
    
    private static func handleChatFailure(
        error: APIError,
        retryAttempt: Int,
        request: ChatRequest,
        onProgress: ((String) -> Void)?,
        completion: @escaping (Result<ChatResponse, APIError>) -> Void
    ) {
        // Check if we should retry
        guard error.shouldRetry && retryAttempt < Config.maxRetries else {
            recordFailure()
            // If we've exhausted retries, provide a more helpful error message
            let finalError: APIError
            if retryAttempt >= Config.maxRetries {
                // All retries exhausted - create enhanced error message
                switch error {
                case .httpError(let code, let details):
                    let baseMessage = APIError.userFriendlyMessage(for: code, details: details)
                    finalError = .httpError(code, "\(baseMessage) Retried \(Config.maxRetries) times without success.")
                case .timeout:
                    finalError = .networkError("Request timed out. Retried \(Config.maxRetries) times without success.")
                case .networkError(let message):
                    finalError = .networkError("\(message) Retried \(Config.maxRetries) times without success.")
                default:
                    finalError = error
                }
            } else {
                finalError = error
            }
            DispatchQueue.main.async {
                completion(.failure(finalError))
            }
            return
        }
        
        // Calculate exponential backoff delay: 1s, 2s, 4s (with jitter)
        let delay = calculateBackoffDelay(retryAttempt: retryAttempt)
        let nextAttempt = retryAttempt + 1
        
        NSLog("[APIClient] Retrying chat request after \(String(format: "%.2f", delay))s (attempt \(nextAttempt)/\(Config.maxRetries))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            chatQuery(request: request, retryAttempt: nextAttempt, onProgress: onProgress, completion: completion)
        }
    }
    
    // MARK: - Circuit Breaker
    
    /// Get current circuit breaker state
    private static func getCircuitBreakerState() -> CircuitBreakerState {
        return circuitBreakerQueue.sync {
            // Check if open state has expired
            if case .open(let openUntil) = circuitBreakerState {
                if openUntil <= Date() {
                    // Transition to half-open
                    circuitBreakerState = .halfOpen(halfOpenUntil: Date().addingTimeInterval(Config.circuitBreakerHalfOpenTimeout))
                }
            }
            
            // Check if half-open state has expired
            if case .halfOpen(let halfOpenUntil) = circuitBreakerState {
                if halfOpenUntil <= Date() {
                    // Transition back to closed
                    circuitBreakerState = .closed
                    consecutiveFailures = 0
                }
            }
            
            return circuitBreakerState
        }
    }
    
    /// Set circuit breaker state
    private static func setCircuitBreakerState(_ state: CircuitBreakerState) {
        circuitBreakerQueue.async {
            circuitBreakerState = state
        }
    }
    
    /// Reset the circuit breaker (useful for testing or after fixing backend issues)
    static func resetCircuitBreaker() {
        circuitBreakerQueue.async {
            consecutiveFailures = 0
            circuitBreakerState = .closed
            NSLog("[APIClient] Circuit breaker manually reset")
        }
    }
    
    private static func recordSuccess() {
        circuitBreakerQueue.async {
            consecutiveFailures = 0
            // If in half-open, transition to closed
            if case .halfOpen = circuitBreakerState {
                circuitBreakerState = .closed
            }
        }
    }
    
    private static func recordFailure() {
        circuitBreakerQueue.async {
            consecutiveFailures += 1
            
            if consecutiveFailures >= Config.circuitBreakerThreshold {
                circuitBreakerState = .open(openUntil: Date().addingTimeInterval(Config.circuitBreakerCooldown))
                NSLog("[APIClient] Circuit breaker opened due to \(consecutiveFailures) consecutive failures. Will retry after \(Config.circuitBreakerCooldown)s")
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Check backend health before making requests
    private static func checkBackendHealth(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(BackendConfig.baseURL)/api/health") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Config.healthCheckTimeout
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            
            // Parse health check response
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String,
               status == "healthy" {
                completion(true)
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
    
    /// Check if network is available before making request
    private static func checkNetworkConnectivity(completion: @escaping (Bool) -> Void) {
        // Quick check using Reachability-like approach
        guard let url = URL(string: "https://www.apple.com") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = Config.networkCheckTimeout
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            let isAvailable = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            completion(isAvailable)
        }
        
        task.resume()
    }
    
    /// Generate a request key for deduplication
    private static func requestKey(for request: RewriteRequest) -> String {
        // Create a hash of the request content
        let content = "\(request.text.prefix(50))|\(request.tone)|\(request.length)"
        return content.hash.description
    }
    
    private static func requestKey(for request: ChatRequest) -> String {
        // Create a hash of the request content
        let content = "\(request.query.prefix(100))"
        return content.hash.description
    }
    
    /// Check if request is duplicate (within last 5 minutes)
    private static func isDuplicateRequest(_ key: String) -> Bool {
        return requestDeduplicationQueue.sync {
            // Clean up old requests
            let now = Date()
            activeRequests = activeRequests.filter { now.timeIntervalSince($0.value) < Config.maxRequestAge }
            
            // Check if this request exists
            if let existingDate = activeRequests[key] {
                return now.timeIntervalSince(existingDate) < 5.0 // 5 second deduplication window
            }
            
            // Record this request
            activeRequests[key] = now
            return false
        }
    }
    
    /// Calculate exponential backoff delay with jitter to prevent thundering herd
    private static func calculateBackoffDelay(retryAttempt: Int) -> TimeInterval {
        let baseDelay = Config.baseRetryDelay * pow(2.0, Double(retryAttempt))
        // Add jitter (±30%) to prevent synchronized retries
        let jitter = Double.random(in: -Config.jitterRange...Config.jitterRange) * baseDelay
        return max(0.1, baseDelay + jitter) // Ensure minimum 0.1s delay
    }
    
    private static func extractErrorMessage(from data: Data?) -> String {
        guard let data = data else { return "" }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return (json["error"] as? String) ?? (json["details"] as? String) ?? ""
            }
        } catch {
            // Ignore parsing errors
        }
        
        return ""
    }
}

