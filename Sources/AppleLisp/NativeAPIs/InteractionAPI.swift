import JavaScriptCore
import AppKit

public struct InteractionAPI: NativeAPIProvider {
    public static var apiName: String { "Interaction" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // Helper to parse options
        func parseOptions(_ value: JSValue?) -> [String: Any] {
            guard let value = value, value.isObject, let dict = value.toDictionary() as? [String: Any] else {
                return [:]
            }
            return dict
        }
        
        // alert(message, optionsOrTitle?)
        // options: { title: String, style: "warning"|"critical"|"info", buttons: [String] }
        let alert: @convention(block) (String, JSValue?) -> String = { message, optionsOrTitle in
            var title = "Alert"
            var style: NSAlert.Style = .informational
            var buttons: [String] = ["OK"]
            
            if let val = optionsOrTitle {
                if val.isString {
                    title = val.toString()
                } else if val.isObject {
                    let opts = parseOptions(val)
                    if let t = opts["title"] as? String { title = t }
                    if let s = opts["style"] as? String {
                        switch s.lowercased() {
                        case "warning": style = .warning
                        case "critical": style = .critical
                        default: style = .informational
                        }
                    }
                    if let b = opts["buttons"] as? [String], !b.isEmpty { buttons = b }
                }
            }
            
            var result = ""
            DispatchQueue.main.sync {
                let alert = NSAlert()
                alert.messageText = title
                alert.informativeText = message
                alert.alertStyle = style
                
                for btn in buttons {
                    alert.addButton(withTitle: btn)
                }
                
                let response = alert.runModal()
                
                // Map response back to button title
                // NSAlert buttons are: First (1000), Second (1001), Third (1002)...
                // But addButton adds them in order (right to left usually, or standard order)
                // The return value rawValue is 1000 + index
                let index = Int(response.rawValue) - 1000
                if index >= 0 && index < buttons.count {
                    result = buttons[index]
                } else {
                    // Fallback or cancel
                    result = "" 
                }
            }
            return result
        }
        api.setObject(unsafeBitCast(alert, to: AnyObject.self),
                      forKeyedSubscript: "alert" as NSString)
        
        // prompt(message, defaultValue?, options?)
        // options: { title: String, buttons: [String], secure: Bool }
        let prompt: @convention(block) (String, String?, JSValue?) -> String? = { message, defaultVal, options in
            var title = "Prompt"
            var buttons = ["OK", "Cancel"]
            var isSecure = false
            
            let opts = parseOptions(options)
            if let t = opts["title"] as? String { title = t }
            if let b = opts["buttons"] as? [String], !b.isEmpty { buttons = b }
            if let s = opts["secure"] as? Bool { isSecure = s }
            
            var result: String? = nil
            DispatchQueue.main.sync {
                let alert = NSAlert()
                alert.messageText = title
                alert.informativeText = message
                
                for btn in buttons {
                    alert.addButton(withTitle: btn)
                }
                
                let frame = NSRect(x: 0, y: 0, width: 250, height: 24)
                let input: NSTextField
                if isSecure {
                    input = NSSecureTextField(frame: frame)
                } else {
                    input = NSTextField(frame: frame)
                }
                input.stringValue = defaultVal ?? ""
                alert.accessoryView = input
                
                // Focus the text field
                alert.window.initialFirstResponder = input
                
                let response = alert.runModal()
                // Assuming first button is "OK" / confirm
                if response == .alertFirstButtonReturn {
                    result = input.stringValue
                }
            }
            return result
        }
        api.setObject(unsafeBitCast(prompt, to: AnyObject.self),
                      forKeyedSubscript: "prompt" as NSString)
        
        // chooseFile(options?) -> String | [String] | null
        // options: { message: String, multiple: Bool, types: [String], directory: String }
        let chooseFile: @convention(block) (JSValue?) -> Any? = { options in
            var message: String?
            var multiple = false
            var types: [String]?
            var directory: String?
            
            if let val = options {
                if val.isString {
                    message = val.toString()
                } else if val.isObject {
                    let opts = parseOptions(val)
                    message = opts["message"] as? String
                    multiple = opts["multiple"] as? Bool ?? false
                    types = opts["types"] as? [String]
                    directory = opts["directory"] as? String
                }
            }
            
            var result: Any? = nil
            DispatchQueue.main.sync {
                let panel = NSOpenPanel()
                panel.canChooseFiles = true
                panel.canChooseDirectories = false
                panel.allowsMultipleSelection = multiple
                if let msg = message { panel.message = msg }
                if let t = types { panel.allowedFileTypes = t }
                if let dir = directory { panel.directoryURL = URL(fileURLWithPath: dir) }
                
                if panel.runModal() == .OK {
                    if multiple {
                        result = panel.urls.map { $0.path }
                    } else {
                        result = panel.url?.path
                    }
                }
            }
            return result
        }
        api.setObject(unsafeBitCast(chooseFile, to: AnyObject.self),
                      forKeyedSubscript: "chooseFile" as NSString)
        
        // chooseFolder(options?) -> String | [String] | null
        // options: { message: String, multiple: Bool, directory: String }
        let chooseFolder: @convention(block) (JSValue?) -> Any? = { options in
            var message: String?
            var multiple = false
            var directory: String?
            
            if let val = options {
                if val.isString {
                    message = val.toString()
                } else if val.isObject {
                    let opts = parseOptions(val)
                    message = opts["message"] as? String
                    multiple = opts["multiple"] as? Bool ?? false
                    directory = opts["directory"] as? String
                }
            }
            
            var result: Any? = nil
            DispatchQueue.main.sync {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = multiple
                if let msg = message { panel.message = msg }
                if let dir = directory { panel.directoryURL = URL(fileURLWithPath: dir) }
                
                if panel.runModal() == .OK {
                    if multiple {
                        result = panel.urls.map { $0.path }
                    } else {
                        result = panel.url?.path
                    }
                }
            }
            return result
        }
        api.setObject(unsafeBitCast(chooseFolder, to: AnyObject.self),
                      forKeyedSubscript: "chooseFolder" as NSString)
        
        return api
    }
}