import JavaScriptCore
import Foundation

/// KeyMap callbacks - set from editor before loading config
public enum KeyMapCallbacks {
    public static var bind: ((String, @escaping () -> Void) -> Bool)?
    public static var unbind: ((String) -> Bool)?
    public static var list: (() -> [String])?
    public static var debug: ((Bool) -> Void)?
}

public struct KeyMapAPI {
    public static var apiName: String { "KeyMap" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // bind(keyCombo, callback) - e.g., bind("ctrl+s", function() { ... })
        let bind: @convention(block) (String, JSValue) -> Bool = { comboStr, callback in
            guard let bindFn = KeyMapCallbacks.bind else {
                print("[KeyMap] Error: bind callback not set")
                return false
            }
            return bindFn(comboStr) {
                callback.call(withArguments: [])
            }
        }
        api.setObject(unsafeBitCast(bind, to: AnyObject.self),
                      forKeyedSubscript: "bind" as NSString)
        
        // unbind(keyCombo)
        let unbind: @convention(block) (String) -> Bool = { comboStr in
            KeyMapCallbacks.unbind?(comboStr) ?? false
        }
        api.setObject(unsafeBitCast(unbind, to: AnyObject.self),
                      forKeyedSubscript: "unbind" as NSString)
        
        // list() - returns array of current bindings
        let list: @convention(block) () -> [String] = {
            KeyMapCallbacks.list?() ?? []
        }
        api.setObject(unsafeBitCast(list, to: AnyObject.self),
                      forKeyedSubscript: "list" as NSString)
        
        // debug(enable) - toggle debug output
        let debug: @convention(block) (Bool) -> Void = { enable in
            KeyMapCallbacks.debug?(enable)
        }
        api.setObject(unsafeBitCast(debug, to: AnyObject.self),
                      forKeyedSubscript: "debug" as NSString)
        
        return api
    }
    
    /// Parse a key sequence string like "C-x C-s" or "ctrl+s"
    public static func parseKeySequence(_ str: String) -> KeySequence? {
        // Support both "C-x C-s" style and "ctrl+x" style
        let parts: [String]
        
        if str.contains(" ") {
            // Emacs style: "C-x C-s"
            parts = str.split(separator: " ").map { String($0) }
        } else {
            // Single key
            parts = [str]
        }
        
        var combos: [KeyCombo] = []
        for part in parts {
            if let combo = parseKeyCombo(part) {
                combos.append(combo)
            } else {
                return nil
            }
        }
        
        return combos.isEmpty ? nil : KeySequence(combos)
    }
    
    /// Parse a single key combo like "C-s" or "ctrl+s"
    public static func parseKeyCombo(_ str: String) -> KeyCombo? {
        let trimmed = str.trimmingCharacters(in: .whitespaces).lowercased()
        
        // Emacs style: "C-x", "M-x", "C-M-x"
        if trimmed.contains("-") && !trimmed.contains("+") {
            let parts = trimmed.split(separator: "-")
            var modifiers: KeyModifiers = .none
            var keyPart: String?
            
            for part in parts {
                switch String(part) {
                case "c": modifiers.insert(.ctrl)
                case "m": modifiers.insert(.alt)
                case "s": modifiers.insert(.shift)
                default: keyPart = String(part)
                }
            }
            
            guard let key = keyPart, key.count == 1, let char = key.first else {
                return nil
            }
            
            if modifiers.contains(.ctrl) {
                return .ctrl(char)
            } else {
                return KeyCombo(Int32(char.asciiValue ?? 0), modifiers: modifiers)
            }
        }
        
        // Legacy style: "ctrl+s"
        let parts = trimmed.split(separator: "+")
        guard !parts.isEmpty else { return nil }
        
        var modifiers: KeyModifiers = .none
        var keyPart: String?
        
        for part in parts {
            switch String(part) {
            case "ctrl", "control": modifiers.insert(.ctrl)
            case "alt", "option", "opt", "meta": modifiers.insert(.alt)
            case "shift": modifiers.insert(.shift)
            default: keyPart = String(part)
            }
        }
        
        guard let key = keyPart else { return nil }
        
        // Special keys
        switch key {
        case "up": return KeyCombo(SpecialKey.up, modifiers: modifiers)
        case "down": return KeyCombo(SpecialKey.down, modifiers: modifiers)
        case "left": return KeyCombo(SpecialKey.left, modifiers: modifiers)
        case "right": return KeyCombo(SpecialKey.right, modifiers: modifiers)
        case "home": return KeyCombo(SpecialKey.home, modifiers: modifiers)
        case "end": return KeyCombo(SpecialKey.end, modifiers: modifiers)
        case "pageup": return KeyCombo(SpecialKey.pageUp, modifiers: modifiers)
        case "pagedown": return KeyCombo(SpecialKey.pageDown, modifiers: modifiers)
        case "enter", "return": return KeyCombo(SpecialKey.enter, modifiers: modifiers)
        case "tab": return KeyCombo(SpecialKey.tab, modifiers: modifiers)
        case "escape", "esc": return KeyCombo(SpecialKey.escape, modifiers: modifiers)
        case "backspace": return KeyCombo(SpecialKey.backspace, modifiers: modifiers)
        case "delete": return KeyCombo(SpecialKey.delete, modifiers: modifiers)
        default:
            if key.count == 1, let char = key.first {
                if modifiers.contains(.ctrl) {
                    return .ctrl(char)
                } else {
                    return KeyCombo(Int32(char.asciiValue ?? 0), modifiers: modifiers)
                }
            }
            return nil
        }
    }
}


