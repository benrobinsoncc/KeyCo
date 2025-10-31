import SwiftUI

@main
struct KeyCoApp: App {
    
    init() {
        // Initialize API key on first launch if not already set
        initializeAPIKeyIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
    
    /// Automatically sets the API key from Config.swift if it doesn't already exist in Keychain
    private func initializeAPIKeyIfNeeded() {
        // Check if API key is configured in Config.swift
        let apiKey = Config.openAIAPIKey
        NSLog("[KeyCoApp] Checking API key configuration...")
        
        // For now, always reset the key to ensure it uses the new access group
        // This is needed to migrate from the old Keychain item (without access group) to the new one
        // TODO: Remove this after testing - only set if key doesn't exist
        NSLog("[KeyCoApp] Force resetting API key to ensure access group is correct...")
        KeychainHelper.deleteAPIKey()
        
        // Check if key already exists
        let hasKey = KeychainHelper.hasAPIKey()
        NSLog("[KeyCoApp] Keychain has API key after reset: \(hasKey)")
        
        // Set the key (we just deleted it above, so this will always run)
        // TODO: Change back to guard !hasKey after testing
        
        // Only store if it's a valid API key (starts with "sk-")
        if apiKey.hasPrefix("sk-") && apiKey != "YOUR_API_KEY_HERE" {
            NSLog("[KeyCoApp] Attempting to store API key from Config.swift...")
            let success = KeychainHelper.storeAPIKey(apiKey)
            if success {
                NSLog("[KeyCoApp] ✅ API key initialized from Config.swift successfully!")
            } else {
                NSLog("[KeyCoApp] ❌ Failed to store API key from Config.swift")
            }
        } else {
            NSLog("[KeyCoApp] ⚠️ API key not configured in Config.swift - please set Config.openAIAPIKey")
            NSLog("[KeyCoApp] API key value: \(apiKey.prefix(10))... (first 10 chars)")
        }
    }
}
