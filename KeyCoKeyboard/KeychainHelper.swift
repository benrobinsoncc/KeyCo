import Foundation
import Security

/// Secure storage helper for sensitive data like API keys
class KeychainHelper {
    
    // Service identifier for the API key
    private static let service = "com.keyco.keyboard"
    private static let apiKeyKey = "chatgpt_api_key"
    
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
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        } else {
            if status == errSecItemNotFound {
                NSLog("[KeychainHelper] API key not found in Keychain")
            } else {
                NSLog("[KeychainHelper] Failed to retrieve API key: \(status)")
            }
            return nil
        }
    }
    
    /// Deletes the stored API key from the Keychain
    /// - Returns: True if deletion was successful, false otherwise
    @discardableResult
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey
        ]
        
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

