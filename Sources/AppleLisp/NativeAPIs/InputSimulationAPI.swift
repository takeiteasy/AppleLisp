import JavaScriptCore
import CoreGraphics
import Foundation

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
            
            // For unicode typing, we use a special event with 0 keycode
            // and set the string directly.
            let utf16 = Array(string.utf16)
            guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false) else {
                return false
            }
            
            utf16.withUnsafeBufferPointer { buffer in
                guard let base = buffer.baseAddress else { return }
                keyDown.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
                keyUp.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
            }
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            
            return true
        }
        api.setObject(unsafeBitCast(typeString, to: AnyObject.self),
                      forKeyedSubscript: "typeString" as NSString)
        
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

        // scroll(deltaY, deltaX?) -> Bool
        // Positive deltaY is up (or down depending on natural scrolling), usually standard is down.
        // Actually for CGEvent scrollWheelEvent2Source:
        // wheel1 is Y (vertical), wheel2 is X (horizontal).
        let scrollInput: @convention(block) (Int32, Int32) -> Bool = { deltaY, deltaX in
             guard let src = CGEventSource(stateID: .hidSystemState) else { return false }
             // wheelCount: 2 (Y and X)
             // wheel1: Y
             // wheel2: X
             guard let event = CGEvent(scrollWheelEvent2Source: src, units: .line, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0) else {
                 return false
             }
             event.post(tap: .cghidEventTap)
             return true
        }
        api.setObject(unsafeBitCast(scrollInput, to: AnyObject.self),
                      forKeyedSubscript: "scrollInput" as NSString)

        // delayInput(seconds) -> Void
        // Using Thread.sleep might block the JS thread, which is what we want for synchronous automation scripts.
        let delayInput: @convention(block) (Double) -> Void = { seconds in
            Thread.sleep(forTimeInterval: seconds)
        }
        api.setObject(unsafeBitCast(delayInput, to: AnyObject.self),
                      forKeyedSubscript: "delayInput" as NSString)
        
        return api
    }
}