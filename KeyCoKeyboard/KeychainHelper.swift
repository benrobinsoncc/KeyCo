import Foundation
import Security

/// Secure storage helper for sensitive data like API keys
class KeychainHelper {
    
    // Service identifier for the API key
    private static let service = "com.keyco.keyboard"
    private static let apiKeyKey = "chatgpt_api_key"
    
    // Keychain Access Group for sharing between app and extension
    // Must match the entitlements: $(AppIdentifierPrefix)group.com.keyco
    // At runtime, this is expanded to: F8ZMT5492T.group.com.keyco
    // Using hardcoded Team ID from project settings
    private static let accessGroup = "F8ZMT5492T.group.com.keyco"
    
    /// Stores an API key securely in the Keychain
    /// - Parameter key: The API key to store
    /// - Returns: True if storage was successful, false otherwise
    @discardableResult
    static func storeAPIKey(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else {
            NSLog("[KeychainHelper] Failed to convert API key to data")
            return false
        }
        
        // Delete existing item first (if it exists)
        deleteAPIKey()
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // DON'T specify access group - let iOS use the one from entitlements automatically
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            NSLog("[KeychainHelper] API key stored successfully")
            return true
        } else {
            NSLog("[KeychainHelper] Failed to store API key: \(status)")
            return false
        }
    }
    
    /// Retrieves the stored API key from the Keychain
    /// - Returns: The API key if found, nil otherwise
    static func retrieveAPIKey() -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // DON'T specify access group - let iOS use the one from entitlements automatically
        // This matches how the app stores it (without explicit access group)
        
        NSLog("[KeychainHelper] [Extension] Retrieving API key (using access group from entitlements)")
        NSLog("[KeychainHelper] Service: \(service), Account: \(apiKeyKey)")
        NSLog("[KeychainHelper] Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        NSLog("[KeychainHelper] Status code: \(status) (errSecSuccess=0, errSecItemNotFound=-25300, errSecNoAccessForItem=-25243)")
        NSLog("[KeychainHelper] Has result: \(result != nil)")
        
        if status == errSecSuccess,
           let data = result as? Data,
           let apiKey = String(data: data, encoding: .utf8) {
            NSLog("[KeychainHelper] ✅ API key retrieved successfully")
            return apiKey
        } else {
            if status == errSecItemNotFound {
                NSLog("[KeychainHelper] ❌ API key not found in Keychain (status: \(status))")
            } else {
                NSLog("[KeychainHelper] ❌ Failed to retrieve API key - Status: \(status)")
            }
            return nil
        }
    }
    
    /// Deletes the stored API key from the Keychain
    /// - Returns: True if deletion was successful, false otherwise
    @discardableResult
    static func deleteAPIKey() -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey
        ]
        
        // DON'T specify access group - let iOS use the one from entitlements automatically
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            NSLog("[KeychainHelper] API key deleted successfully")
            return true
        } else {
            NSLog("[KeychainHelper] Failed to delete API key: \(status)")
            return false
        }
    }
    
    /// Checks if an API key exists in the Keychain
    /// - Returns: True if an API key is stored, false otherwise
    static func hasAPIKey() -> Bool {
        return retrieveAPIKey() != nil
    }
    
    // MARK: - Setup Helper
    
    /// One-time setup method to initialize your ChatGPT API key
    /// 
    /// **Usage:**
    /// 1. Add this call temporarily in your code (e.g., in viewDidLoad() or AppDelegate)
    /// 2. Replace "YOUR_API_KEY_HERE" with your actual OpenAI API key
    /// 3. Run the app once to store it
    /// 4. Remove this call after the key is stored
    ///
    /// Example:
    /// ```swift
    /// KeychainHelper.initializeAPIKey("sk-...")
    /// ```
    ///
    /// Or use the Xcode debugger (lldb):
    /// ```
    /// po KeychainHelper.storeAPIKey("your-api-key")
    /// ```
    static func initializeAPIKey(_ key: String) {
        if storeAPIKey(key) {
            NSLog("[KeychainHelper] ✅ API key initialized successfully")
        } else {
            NSLog("[KeychainHelper] ❌ Failed to initialize API key")
        }
    }
}

