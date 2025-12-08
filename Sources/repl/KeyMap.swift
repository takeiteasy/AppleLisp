import Foundation

/// Key modifiers for key combinations
public struct KeyModifiers: OptionSet, Hashable {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let ctrl  = KeyModifiers(rawValue: 1 << 0)
    public static let alt   = KeyModifiers(rawValue: 1 << 1)
    public static let shift = KeyModifiers(rawValue: 1 << 2)
    
    public static let none: KeyModifiers = []
}

/// Represents a key combination (modifiers + key)
public struct KeyCombo: Hashable, CustomStringConvertible {
    public let modifiers: KeyModifiers
    public let key: Int32
    
    public init(_ key: Int32, modifiers: KeyModifiers = .none) {
        self.modifiers = modifiers
        self.key = key
    }
    
    /// Create from Ctrl+key (e.g., Ctrl+S)
    public static func ctrl(_ char: Character) -> KeyCombo {
        let asciiValue = Int32(char.uppercased().first?.asciiValue ?? 0)
        // Ctrl+A = 1, Ctrl+B = 2, etc.
        let ctrlCode = asciiValue - 64  // 'A' is 65, Ctrl+A is 1
        return KeyCombo(ctrlCode, modifiers: .ctrl)
    }
    
    /// Create from regular key
    public static func key(_ char: Character) -> KeyCombo {
        return KeyCombo(Int32(char.asciiValue ?? 0))
    }
    
    public var description: String {
        var parts: [String] = []
        if modifiers.contains(.ctrl) { parts.append("C") }
        if modifiers.contains(.alt) { parts.append("M") }  // Meta = Alt
        if modifiers.contains(.shift) { parts.append("S") }
        
        if key >= 32 && key < 127 {
            parts.append(String(Character(UnicodeScalar(UInt8(key)))).lowercased())
        } else if key >= 1 && key <= 26 {
            parts.append(String(Character(UnicodeScalar(UInt8(key + 64)))).lowercased())
        } else {
            parts.append("\(key)")
        }
        return parts.joined(separator: "-")
    }
}

/// Special keys
public enum SpecialKey {
    public static let up: Int32 = 259       // KEY_UP
    public static let down: Int32 = 258     // KEY_DOWN
    public static let left: Int32 = 260     // KEY_LEFT
    public static let right: Int32 = 261    // KEY_RIGHT
    public static let home: Int32 = 262     // KEY_HOME
    public static let end: Int32 = 360      // KEY_END
    public static let pageUp: Int32 = 339   // KEY_PPAGE
    public static let pageDown: Int32 = 338 // KEY_NPAGE
    public static let backspace: Int32 = 127
    public static let delete: Int32 = 330   // KEY_DC
    public static let enter: Int32 = 10
    public static let tab: Int32 = 9
    public static let escape: Int32 = 27
}

/// Key binding action
public typealias KeyAction = () -> Void

/// Represents a key sequence (e.g., C-x C-s)
public struct KeySequence: Hashable, CustomStringConvertible {
    public let combos: [KeyCombo]
    
    public init(_ combos: [KeyCombo]) {
        self.combos = combos
    }
    
    public init(_ combo: KeyCombo) {
        self.combos = [combo]
    }
    
    public var description: String {
        combos.map { $0.description }.joined(separator: " ")
    }
}

/// Key map for managing key bindings with key sequence support
public class KeyMap {
    private var bindings: [KeySequence: KeyAction] = [:]
    private var namedBindings: [String: KeySequence] = [:]
    
    // Pending key sequence (for multi-key combos like C-x C-s)
    private var pendingSequence: [KeyCombo] = []
    public var pendingPrefix: String { pendingSequence.map { $0.description }.joined(separator: " ") }
    public var hasPending: Bool { !pendingSequence.isEmpty }
    
    public init() {}
    
    /// Bind a key sequence to an action
    public func bind(_ seq: KeySequence, name: String? = nil, to action: @escaping KeyAction) {
        bindings[seq] = action
        if let name = name {
            namedBindings[name] = seq
        }
    }
    
    /// Bind a single key combo to an action
    public func bind(_ combo: KeyCombo, name: String? = nil, to action: @escaping KeyAction) {
        bind(KeySequence(combo), name: name, to: action)
    }
    
    /// Bind Ctrl+key to an action
    public func bindCtrl(_ char: Character, name: String? = nil, to action: @escaping KeyAction) {
        bind(.ctrl(char), name: name, to: action)
    }
    
    /// Bind a key sequence like "C-x C-s"
    public func bindSequence(_ first: KeyCombo, _ second: KeyCombo, name: String? = nil, to action: @escaping KeyAction) {
        bind(KeySequence([first, second]), name: name, to: action)
    }
    
    /// Unbind a key combo
    public func unbind(_ combo: KeyCombo) {
        bindings.removeValue(forKey: KeySequence(combo))
    }
    
    /// Cancel pending key sequence
    public func cancelPending() {
        pendingSequence = []
    }
    
    /// Handle a key press, returns true if handled (or waiting for more keys)
    @discardableResult
    public func handle(_ keyCode: Int32) -> Bool {
        let combo: KeyCombo
        
        // Check for Ctrl+key (codes 1-26)
        if keyCode >= 1 && keyCode <= 26 {
            combo = KeyCombo(keyCode, modifiers: .ctrl)
        } else {
            combo = KeyCombo(keyCode)
        }
        
        // Add to pending sequence
        pendingSequence.append(combo)
        let seq = KeySequence(pendingSequence)
        
        // Check for exact match
        if let action = bindings[seq] {
            pendingSequence = []
            action()
            return true
        }
        
        // Check if this could be a prefix of a longer sequence
        let isPrefix = bindings.keys.contains { $0.combos.starts(with: pendingSequence) }
        if isPrefix {
            return true  // Wait for more keys
        }
        
        // No match and not a prefix - reset
        pendingSequence = []
        return false
    }
    
    /// Get binding for a named action
    public func binding(named name: String) -> KeySequence? {
        return namedBindings[name]
    }
    
    /// List all bindings
    public var allBindings: [(seq: KeySequence, name: String?)] {
        var result: [(KeySequence, String?)] = []
        for (seq, _) in bindings {
            let name = namedBindings.first { $0.value == seq }?.key
            result.append((seq, name))
        }
        return result
    }
}

