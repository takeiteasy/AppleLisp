import JavaScriptCore
import CoreGraphics

public struct InputSimulationAPI: NativeAPIProvider {
    public static var apiName: String { "InputSimulation" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // keyPress(keyCode, modifiers?) -> Bool
        // Modifiers: ["cmd", "opt", "shift", "ctrl"]
        let keyPress: @convention(block) (UInt16, [String]?) -> Bool = { keyCode, modifiers in
            guard let src = CGEventSource(stateID: .hidSystemState) else { return false }
            
            var flags: CGEventFlags = []
            if let mods = modifiers {
                for mod in mods {
                    switch mod.lowercased() {
                    case "cmd", "command": flags.insert(.maskCommand)
                    case "opt", "option", "alt": flags.insert(.maskAlternate)
                    case "shift": flags.insert(.maskShift)
                    case "ctrl", "control": flags.insert(.maskControl)
                    default: break
                    }
                }
            }
            
            guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(keyCode), keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(keyCode), keyDown: false) else {
                return false
            }
            
            keyDown.flags = flags
            keyUp.flags = flags
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            
            return true
        }
        api.setObject(unsafeBitCast(keyPress, to: AnyObject.self),
                      forKeyedSubscript: "keyPress" as NSString)
        
        // typeString(string) -> Bool
        let typeString: @convention(block) (String) -> Bool = { string in
            guard let src = CGEventSource(stateID: .hidSystemState) else { return false }
            
            for char in string.utf16 {
                // This is a simplified typing simulation. 
                // For full support we'd need to map chars to keycodes, which is complex.
                // However, CGEvent(keyboardEventSource:virtualKey:keyDown:) isn't enough for unicode.
                // We can try a lower level approach or mapping.
                // A common workaround is setting keyboard layout, but that's hard.
                // Actually, UniChar injection is possible with CGEventKeyboardSetUnicodeString (deprecated or private in Swift sometimes?)
                // Let's use a simpler approach: key strokes for standard ASCII if possible, or just fail for complex ones for now.
                // Better approach for "typeString": specific usage often involves standard keys.
                
                // Note: CGEvent doesn't easily support "just type this char" without keycode mapping.
                // Let's try to simulate key presses for known ASCII or use the specific API if accessible.
                // But Swift CoreGraphics overlay might hide legacy functions.
                
                // Let's stick to simple "events from string" if possible, but standard API lacks it.
                // We'll leave it as "keyPress" focused or implement a basic mapper if really needed.
                // Actually, let's omit "typeString" for now if it's too complex to do robustly without a huge map,
                // OR just expose mouse functions which are easier.
            }
            // For now, let's just implement mouse functions and keyPress.
            return false
        }
        // Skipping typeString for now to keep implementation clean.
        
        // mouseMove(x, y) -> Bool
        let mouseMove: @convention(block) (Double, Double) -> Bool = { x, y in
            guard let src = CGEventSource(stateID: .hidSystemState) else { return false }
            guard let event = CGEvent(mouseEventSource: src, mouseType: .mouseMoved,
                                      mouseCursorPosition: CGPoint(x: x, y: y),
                                      mouseButton: .left) else { return false }
            event.post(tap: .cghidEventTap)
            return true
        }
        api.setObject(unsafeBitCast(mouseMove, to: AnyObject.self),
                      forKeyedSubscript: "mouseMove" as NSString)
        
        // mouseClick(x, y, button?) -> Bool
        // button: "left", "right"
        let mouseClick: @convention(block) (Double, Double, String?) -> Bool = { x, y, button in
            guard let src = CGEventSource(stateID: .hidSystemState) else { return false }
            let btn = button?.lowercased() ?? "left"
            let mouseTypeDown: CGEventType
            let mouseTypeUp: CGEventType
            let mouseButton: CGMouseButton
            
            if btn == "right" {
                mouseTypeDown = .rightMouseDown
                mouseTypeUp = .rightMouseUp
                mouseButton = .right
            } else {
                mouseTypeDown = .leftMouseDown
                mouseTypeUp = .leftMouseUp
                mouseButton = .left
            }
            
            let point = CGPoint(x: x, y: y)
            guard let down = CGEvent(mouseEventSource: src, mouseType: mouseTypeDown, mouseCursorPosition: point, mouseButton: mouseButton),
                  let up = CGEvent(mouseEventSource: src, mouseType: mouseTypeUp, mouseCursorPosition: point, mouseButton: mouseButton) else {
                return false
            }
            
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            return true
        }
        api.setObject(unsafeBitCast(mouseClick, to: AnyObject.self),
                      forKeyedSubscript: "mouseClick" as NSString)
        
        // getMousePosition() -> {x: Double, y: Double}
        let getMousePosition: @convention(block) () -> [String: Double] = {
            if let event = CGEvent(source: nil) {
                let loc = event.location
                return ["x": loc.x, "y": loc.y]
            }
            return ["x": 0, "y": 0]
        }
        api.setObject(unsafeBitCast(getMousePosition, to: AnyObject.self),
                      forKeyedSubscript: "getMousePosition" as NSString)
        
        return api
    }
}
