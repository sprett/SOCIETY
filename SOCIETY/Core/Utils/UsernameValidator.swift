//
//  UsernameValidator.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 12/02/2026.
//

import Foundation

/// Validates and sanitizes usernames according to app rules.
struct UsernameValidator {
    /// Characters allowed in usernames: lowercase alphanumeric, underscore, hyphen, period
    static let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    
    /// Characters allowed at start and end: lowercase letters and numbers only
    static let alphanumericCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    
    /// Minimum username length
    static let minimumLength = 3
    
    /// Validates a username string.
    /// - Parameter username: The username to validate
    /// - Returns: true if valid, false otherwise
    static func isValid(_ username: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minimumLength else { return false }
        
        // Check all characters are valid (lowercase alphanumeric, _, -, .)
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else { return false }
        
        // Check first character is alphanumeric (not _, -, .)
        guard let firstChar = trimmed.first,
              firstChar.unicodeScalars.allSatisfy({ alphanumericCharacters.contains($0) }) else {
            return false
        }
        
        // Check last character is alphanumeric (not _, -, .)
        guard let lastChar = trimmed.last,
              lastChar.unicodeScalars.allSatisfy({ alphanumericCharacters.contains($0) }) else {
            return false
        }
        
        return true
    }
    
    /// Filters and normalizes a string to only contain valid username characters.
    /// Converts to lowercase and removes invalid characters.
    /// - Parameter input: The input string
    /// - Returns: String with only valid characters, in lowercase
    static func filter(_ input: String) -> String {
        return input.lowercased().unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map { String($0) }
            .joined()
    }
    
    /// Validates a username and returns an error message if invalid.
    /// - Parameter username: The username to validate
    /// - Returns: Error message if invalid, nil if valid
    static func validationError(for username: String) -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "Username is required"
        }
        
        if trimmed.count < minimumLength {
            return "Username must be at least \(minimumLength) characters"
        }
        
        // Check for uppercase letters
        if trimmed != trimmed.lowercased() {
            return "Username must be lowercase"
        }
        
        // Check all characters are valid
        if !trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            return "Only lowercase letters, numbers, _, -, and . allowed"
        }
        
        // Check first character
        if let firstChar = trimmed.first,
           !firstChar.unicodeScalars.allSatisfy({ alphanumericCharacters.contains($0) }) {
            return "Username must start with a letter or number"
        }
        
        // Check last character
        if let lastChar = trimmed.last,
           !lastChar.unicodeScalars.allSatisfy({ alphanumericCharacters.contains($0) }) {
            return "Username must end with a letter or number"
        }
        
        return nil
    }
}
