import JavaScriptCore
import CoreGraphics
import Foundation
import Carbon.HIToolbox

// MARK: - Modifier Flags

/// Custom modifier flags that are Hashable (CGEventFlags is not)
public struct ModifierFlags: OptionSet, Hashable {
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    public static let command = ModifierFlags(rawValue: 1 << 0)
    public static let shift = ModifierFlags(rawValue: 1 << 1)
    public static let control = ModifierFlags(rawValue: 1 << 2)
    public static let option = ModifierFlags(rawValue: 1 << 3)
    
    /// Create from CGEventFlags
    public static func from(_ flags: CGEventFlags) -> ModifierFlags {
        var result = ModifierFlags()
        if flags.contains(.maskCommand) { result.insert(.command) }
        if flags.contains(.maskShift) { result.insert(.shift) }
        if flags.contains(.maskControl) { result.insert(.control) }
        if flags.contains(.maskAlternate) { result.insert(.option) }
        return result
    }
    
    /// Convert to array of strings for JS
    public func toArray() -> [String] {
        var result: [String] = []
        if contains(.command) { result.append("command") }
        if contains(.control) { result.append("control") }
        if contains(.option) { result.append("option") }
        if contains(.shift) { result.append("shift") }
        return result
    }
}

// MARK: - Key Binding Data Structures

/// Represents a single key press with modifiers
public struct KeyBinding: Hashable, CustomStringConvertible {
    public let key: String
    public let keyCode: Int64
    public let modifiers: ModifierFlags
    
    public init(key: String, keyCode: Int64 = 0, modifiers: ModifierFlags = []) {
        self.key = key.lowercased()
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
    
    /// Create a KeyBinding from a CGEvent
    public static func from(event: CGEvent) -> KeyBinding? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let chars = event.keyboardCharacter ?? ""
        
        guard !chars.isEmpty || keyCode > 0 else { return nil }
        
        let mods = ModifierFlags.from(event.flags)
        
        // Use key character if available, otherwise use special key name
        let keyName = chars.isEmpty ? KeyBinding.specialKeyName(for: keyCode) : chars.lowercased()
        
        return KeyBinding(key: keyName, keyCode: keyCode, modifiers: mods)
    }
    
    /// Get human-readable name for special keys
    private static func specialKeyName(for keyCode: Int64) -> String {
        switch Int(keyCode) {
        case kVK_Return: return "return"
        case kVK_Tab: return "tab"
        case kVK_Space: return "space"
        case kVK_Delete: return "backspace"
        case kVK_Escape: return "escape"
        case kVK_ForwardDelete: return "delete"
        case kVK_Home: return "home"
        case kVK_End: return "end"
        case kVK_PageUp: return "pageup"
        case kVK_PageDown: return "pagedown"
        case kVK_LeftArrow: return "left"
        case kVK_RightArrow: return "right"
        case kVK_DownArrow: return "down"
        case kVK_UpArrow: return "up"
        case kVK_F1: return "f1"
        case kVK_F2: return "f2"
        case kVK_F3: return "f3"
        case kVK_F4: return "f4"
        case kVK_F5: return "f5"
        case kVK_F6: return "f6"
        case kVK_F7: return "f7"
        case kVK_F8: return "f8"
        case kVK_F9: return "f9"
        case kVK_F10: return "f10"
        case kVK_F11: return "f11"
        case kVK_F12: return "f12"
        default: return "key\(keyCode)"
        }
    }
    
    public var description: String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("CMD") }
        if modifiers.contains(.control) { parts.append("C") }
        if modifiers.contains(.option) { parts.append("M") }
        if modifiers.contains(.shift) { parts.append("S") }
        parts.append(key.uppercased())
        return parts.joined(separator: "-")
    }
}

/// Extension to get keyboard character from CGEvent
extension CGEvent {
    var keyboardCharacter: String? {
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        self.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        if length > 0 {
            return String(utf16CodeUnits: chars, count: length)
        }
        return nil
    }
}

/// Represents a sequence of key presses (e.g., C-x C-f)
public struct KeySequence: Hashable, CustomStringConvertible {
    public let keys: [KeyBinding]
    
    public init(_ keys: [KeyBinding]) {
        self.keys = keys
    }
    
    public var description: String {
        return keys.map { $0.description }.joined(separator: " ")
    }
}

// MARK: - Key Notation Parser

/// Parses Emacs-style key notation (e.g., "C-x C-f", "M-x", "CMD-s")
public struct KeyNotationParser {
    
    /// Parse a key notation string into a KeySequence
    public static func parse(_ notation: String) -> KeySequence? {
        let parts = notation.split(separator: " ")
        var bindings: [KeyBinding] = []
        
        for part in parts {
            guard let binding = parseSingleKey(String(part)) else {
                return nil
            }
            bindings.append(binding)
        }
        
        return bindings.isEmpty ? nil : KeySequence(bindings)
    }
    
    /// Parse a single key notation (e.g., "C-x", "M-f")
    private static func parseSingleKey(_ notation: String) -> KeyBinding? {
        var components = notation.split(separator: "-").map { String($0) }
        guard !components.isEmpty else { return nil }
        
        // Last component is the key
        let keyPart = components.removeLast()
        
        var mods = ModifierFlags()
        for component in components {
            switch component.uppercased() {
            case "C", "CTRL", "CONTROL":
                mods.insert(.control)
            case "M", "META", "ALT", "OPT", "OPTION":
                mods.insert(.option)
            case "S", "SHIFT":
                mods.insert(.shift)
            case "CMD", "COMMAND", "SUPER":
                mods.insert(.command)
            default:
                // Unknown modifier, fail gracefully
                return nil
            }
        }
        
        return KeyBinding(key: keyPart.lowercased(), modifiers: mods)
    }
}

// MARK: - Global Key Handler

/// Handles global keyboard event capture via CGEventTap
public class GlobalKeyHandler {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let callback: (CGEvent, CGEventType) -> Bool
    private var isEnabled: Bool = false
    
    public init(callback: @escaping (CGEvent, CGEventType) -> Bool) {
        self.callback = callback
    }
    
    deinit {
        stop()
    }
    
    /// Start capturing keyboard events
    public func start() -> Bool {
        guard eventTap == nil else { return true } // Already started
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue)
        
        // Create the event tap with user info pointer
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                
                let handler = Unmanaged<GlobalKeyHandler>.fromOpaque(refcon).takeUnretainedValue()
                
                // Handle tap disabled event
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = handler.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passRetained(event)
                }
                
                if handler.callback(event, type) {
                    return nil // Consume event
                }
                return Unmanaged.passRetained(event) // Pass through
            },
            userInfo: refcon
        ) else {
            return false
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        
        CGEvent.tapEnable(tap: tap, enable: true)
        isEnabled = true
        
        return true
    }
    
    /// Stop capturing keyboard events
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isEnabled = false
    }
    
    /// Check if the handler is currently active
    public var isActive: Bool {
        return isEnabled && eventTap != nil
    }
}

// MARK: - Key Binding Manager

/// Manages key bindings and sequence matching
public class KeyBindingManager {
    private var bindings: [KeySequence: String] = [:]  // Maps sequence to callback ID
    private var callbacks: [String: JSValue] = [:]
    private var currentSequence: [KeyBinding] = []
    private var sequenceTimer: Timer?
    private var sequenceTimeout: TimeInterval
    
    /// Callback for when partial sequence changes (for UI feedback)
    public var onSequenceChange: ((String?) -> Void)?
    
    /// Callback for when a key event is received (for raw key handling)
    public var onRawKeyEvent: ((KeyBinding, String) -> Bool)?
    
    /// Callback for when sequence is cancelled (e.g., by Escape)
    public var onSequenceCancelled: (() -> Void)?
    
    /// Initialize with timeout. Default is 0 (wait indefinitely like Emacs).
    /// Use Escape key to cancel a pending sequence.
    public init(sequenceTimeout: TimeInterval = 0) {
        self.sequenceTimeout = sequenceTimeout
    }
    
    /// Set the sequence timeout duration
    public func setTimeout(_ timeout: TimeInterval) {
        self.sequenceTimeout = timeout
    }
    
    /// Register a key binding with a callback
    public func register(sequence: KeySequence, callbackId: String, callback: JSValue) {
        bindings[sequence] = callbackId
        callbacks[callbackId] = callback
    }
    
    /// Unregister a key binding
    public func unregister(sequence: KeySequence) {
        if let callbackId = bindings.removeValue(forKey: sequence) {
            callbacks.removeValue(forKey: callbackId)
        }
    }
    
    /// Unregister a binding by its callback ID
    public func unregisterById(_ callbackId: String) {
        bindings = bindings.filter { $0.value != callbackId }
        callbacks.removeValue(forKey: callbackId)
    }
    
    /// Clear all bindings
    public func clearAll() {
        bindings.removeAll()
        callbacks.removeAll()
        resetSequence()
    }
    
    /// Check if we're currently in the middle of a key sequence
    public var isInSequence: Bool {
        return !currentSequence.isEmpty
    }
    
    /// Handle an incoming key event
    public func handleKey(_ event: CGEvent, type: CGEventType) -> Bool {
        // Only process keyDown events for binding matching
        guard type == .keyDown else { return false }
        
        guard let binding = KeyBinding.from(event: event) else {
            return false
        }
        
        // Check for Escape key - cancels current sequence (like Emacs C-g behavior)
        // Only cancel if we're in the middle of a sequence
        if binding.key == "escape" && binding.modifiers.isEmpty && isInSequence {
            cancelSequence()
            return true  // Consume the escape key
        }
        
        // Check for raw key event handler first
        if let rawHandler = onRawKeyEvent {
            if rawHandler(binding, binding.description) {
                return true
            }
        }
        
        currentSequence.append(binding)
        
        // Start/reset timer only if timeout > 0
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        if sequenceTimeout > 0 {
            sequenceTimer = Timer.scheduledTimer(withTimeInterval: sequenceTimeout, repeats: false) { [weak self] _ in
                self?.resetSequence()
            }
        }
        
        // Check for exact match
        let seq = KeySequence(currentSequence)
        if let callbackId = bindings[seq], let callback = callbacks[callbackId] {
            resetSequence()
            // Call the JS callback
            callback.call(withArguments: [])
            return true
        }
        
        // Check if current sequence is a prefix of any binding
        let isPrefix = bindings.keys.contains { keySeq in
            guard keySeq.keys.count > currentSequence.count else { return false }
            return Array(keySeq.keys.prefix(currentSequence.count)) == currentSequence
        }
        
        if isPrefix {
            // Notify about partial sequence for UI feedback
            onSequenceChange?(currentSequenceString())
            return true  // Consume event, waiting for more keys
        } else {
            resetSequence()
            return false  // Not a valid sequence, pass through
        }
    }
    
    /// Get the current partial sequence as a string
    public func currentSequenceString() -> String? {
        guard !currentSequence.isEmpty else { return nil }
        return currentSequence.map { $0.description }.joined(separator: " ") + " -"
    }
    
    /// Cancel the current sequence (called by Escape key)
    public func cancelSequence() {
        let wasInSequence = !currentSequence.isEmpty
        currentSequence.removeAll()
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        onSequenceChange?(nil)
        if wasInSequence {
            onSequenceCancelled?()
        }
    }
    
    /// Reset the current sequence (internal use)
    private func resetSequence() {
        currentSequence.removeAll()
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        onSequenceChange?(nil)
    }
    
    /// Get all registered bindings as a dictionary for JS
    public func listBindings() -> [[String: Any]] {
        return bindings.map { (seq, callbackId) in
            return [
                "sequence": seq.description,
                "callbackId": callbackId
            ]
        }
    }
}

// MARK: - KeyBinding API Provider

public struct KeyBindingAPI: NativeAPIProvider {
    public static var apiName: String { "KeyBinding" }
    
    // Shared state for the key binding system
    private static var keyHandler: GlobalKeyHandler?
    private static var bindingManager: KeyBindingManager?
    private static var rawKeyCallback: JSValue?
    private static var sequenceCallback: JSValue?
    private static var cancelCallback: JSValue?
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // Initialize the binding manager if not already done
        if bindingManager == nil {
            bindingManager = KeyBindingManager()
        }
        
        // start() -> Bool
        // Start the global key capture
        let start: @convention(block) () -> Bool = {
            guard keyHandler == nil else { return true }
            
            let manager = bindingManager!
            keyHandler = GlobalKeyHandler { event, type in
                // Check for raw key handler first
                if let rawCallback = rawKeyCallback, type == .keyDown {
                    if let binding = KeyBinding.from(event: event) {
                        let eventData: [String: Any] = [
                            "key": binding.key,
                            "keyCode": binding.keyCode,
                            "modifiers": binding.modifiers.toArray(),
                            "description": binding.description
                        ]
                        if let result = rawCallback.call(withArguments: [eventData]), result.toBool() {
                            return true
                        }
                    }
                }
                
                return manager.handleKey(event, type: type)
            }
            
            return keyHandler?.start() ?? false
        }
        api.setObject(unsafeBitCast(start, to: AnyObject.self),
                      forKeyedSubscript: "start" as NSString)
        
        // stop() -> Void
        // Stop the global key capture
        let stop: @convention(block) () -> Void = {
            keyHandler?.stop()
            keyHandler = nil
        }
        api.setObject(unsafeBitCast(stop, to: AnyObject.self),
                      forKeyedSubscript: "stop" as NSString)
        
        // isActive() -> Bool
        // Check if key capture is active
        let isActive: @convention(block) () -> Bool = {
            return keyHandler?.isActive ?? false
        }
        api.setObject(unsafeBitCast(isActive, to: AnyObject.self),
                      forKeyedSubscript: "isActive" as NSString)
        
        // bind(notation, callback) -> String | null
        // Register a key binding, returns binding ID or null on failure
        let bind: @convention(block) (String, JSValue) -> String? = { notation, callback in
            guard let sequence = KeyNotationParser.parse(notation) else {
                return nil
            }
            
            let callbackId = UUID().uuidString
            bindingManager?.register(sequence: sequence, callbackId: callbackId, callback: callback)
            
            return callbackId
        }
        api.setObject(unsafeBitCast(bind, to: AnyObject.self),
                      forKeyedSubscript: "bind" as NSString)
        
        // unbind(notation) -> Bool
        // Unregister a key binding by notation
        let unbind: @convention(block) (String) -> Bool = { notation in
            guard let sequence = KeyNotationParser.parse(notation) else {
                return false
            }
            bindingManager?.unregister(sequence: sequence)
            return true
        }
        api.setObject(unsafeBitCast(unbind, to: AnyObject.self),
                      forKeyedSubscript: "unbind" as NSString)
        
        // unbindById(id) -> Void
        // Unregister a key binding by its ID
        let unbindById: @convention(block) (String) -> Void = { callbackId in
            bindingManager?.unregisterById(callbackId)
        }
        api.setObject(unsafeBitCast(unbindById, to: AnyObject.self),
                      forKeyedSubscript: "unbindById" as NSString)
        
        // clearAll() -> Void
        // Clear all key bindings
        let clearAll: @convention(block) () -> Void = {
            bindingManager?.clearAll()
        }
        api.setObject(unsafeBitCast(clearAll, to: AnyObject.self),
                      forKeyedSubscript: "clearAll" as NSString)
        
        // listBindings() -> Array
        // List all registered bindings
        let listBindings: @convention(block) () -> [[String: Any]] = {
            return bindingManager?.listBindings() ?? []
        }
        api.setObject(unsafeBitCast(listBindings, to: AnyObject.self),
                      forKeyedSubscript: "listBindings" as NSString)
        
        // getCurrentSequence() -> String | null
        // Get the current partial key sequence (for UI feedback)
        let getCurrentSequence: @convention(block) () -> String? = {
            return bindingManager?.currentSequenceString()
        }
        api.setObject(unsafeBitCast(getCurrentSequence, to: AnyObject.self),
                      forKeyedSubscript: "getCurrentSequence" as NSString)
        
        // onSequenceChange(callback) -> Void
        // Set a callback for when the partial sequence changes
        let onSequenceChange: @convention(block) (JSValue) -> Void = { callback in
            sequenceCallback = callback
            bindingManager?.onSequenceChange = { sequence in
                callback.call(withArguments: [sequence as Any])
            }
        }
        api.setObject(unsafeBitCast(onSequenceChange, to: AnyObject.self),
                      forKeyedSubscript: "onSequenceChange" as NSString)
        
        // onRawKey(callback) -> Void
        // Set a callback for all key events (before binding matching)
        // Callback receives {key, keyCode, modifiers, description}
        // Return true to consume the event
        let onRawKey: @convention(block) (JSValue?) -> Void = { callback in
            rawKeyCallback = callback
        }
        api.setObject(unsafeBitCast(onRawKey, to: AnyObject.self),
                      forKeyedSubscript: "onRawKey" as NSString)
        
        // onCancel(callback) -> Void
        // Set a callback for when a sequence is cancelled (by Escape key)
        let onCancel: @convention(block) (JSValue) -> Void = { callback in
            cancelCallback = callback
            bindingManager?.onSequenceCancelled = {
                callback.call(withArguments: [])
            }
        }
        api.setObject(unsafeBitCast(onCancel, to: AnyObject.self),
                      forKeyedSubscript: "onCancel" as NSString)
        
        // cancel() -> Void
        // Manually cancel the current key sequence
        let cancel: @convention(block) () -> Void = {
            bindingManager?.cancelSequence()
        }
        api.setObject(unsafeBitCast(cancel, to: AnyObject.self),
                      forKeyedSubscript: "cancel" as NSString)
        
        // isInSequence() -> Bool
        // Check if we're currently in the middle of a key sequence
        let isInSequence: @convention(block) () -> Bool = {
            return bindingManager?.isInSequence ?? false
        }
        api.setObject(unsafeBitCast(isInSequence, to: AnyObject.self),
                      forKeyedSubscript: "isInSequence" as NSString)
        
        // parseNotation(notation) -> Array | null
        // Parse a key notation string into its components (for debugging)
        let parseNotation: @convention(block) (String) -> [[String: Any]]? = { notation in
            guard let sequence = KeyNotationParser.parse(notation) else {
                return nil
            }
            return sequence.keys.map { binding in
                [
                    "key": binding.key,
                    "modifiers": binding.modifiers.toArray(),
                    "description": binding.description
                ]
            }
        }
        api.setObject(unsafeBitCast(parseNotation, to: AnyObject.self),
                      forKeyedSubscript: "parseNotation" as NSString)
        
        // setTimeout(seconds) -> Void
        // Set the sequence timeout duration.
        // Default is 0 (wait indefinitely). Use Escape to cancel.
        // Set to > 0 to auto-cancel after that many seconds.
        let setTimeout: @convention(block) (Double) -> Void = { seconds in
            bindingManager?.setTimeout(seconds)
        }
        api.setObject(unsafeBitCast(setTimeout, to: AnyObject.self),
                      forKeyedSubscript: "setTimeout" as NSString)
        
        return api
    }
}
