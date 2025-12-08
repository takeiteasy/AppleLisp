import JavaScriptCore
import Foundation

/// Editor action callbacks - set these from the repl target before loading Editor API
public enum EditorCallbacks {
    public static var moveUp: (() -> Void)?
    public static var moveDown: (() -> Void)?
    public static var moveLeft: (() -> Void)?
    public static var moveRight: (() -> Void)?
    public static var moveHome: (() -> Void)?
    public static var moveEnd: (() -> Void)?
    public static var pageUp: (() -> Void)?
    public static var pageDown: (() -> Void)?
    public static var save: (() -> Void)?
    public static var quit: (() -> Void)?
    public static var insertChar: ((String) -> Void)?
    public static var insertText: ((String) -> Void)?
    public static var newline: (() -> Void)?
    public static var backspace: (() -> Void)?
    public static var deleteChar: (() -> Void)?
    public static var getCursorX: (() -> Int)?
    public static var getCursorY: (() -> Int)?
    public static var getLineCount: (() -> Int)?
    public static var getCurrentLine: (() -> String)?
    public static var setStatusMessage: ((String) -> Void)?
    
    // S-expression navigation
    public static var forwardSexp: (() -> Void)?
    public static var backwardSexp: (() -> Void)?
    public static var gotoMatchingParen: (() -> Void)?
    public static var killSexp: (() -> Void)?
}

public struct EditorAPI {
    public static var apiName: String { "Editor" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // Movement functions
        let moveUp: @convention(block) () -> Void = { EditorCallbacks.moveUp?() }
        api.setObject(unsafeBitCast(moveUp, to: AnyObject.self), forKeyedSubscript: "moveUp" as NSString)
        
        let moveDown: @convention(block) () -> Void = { EditorCallbacks.moveDown?() }
        api.setObject(unsafeBitCast(moveDown, to: AnyObject.self), forKeyedSubscript: "moveDown" as NSString)
        
        let moveLeft: @convention(block) () -> Void = { EditorCallbacks.moveLeft?() }
        api.setObject(unsafeBitCast(moveLeft, to: AnyObject.self), forKeyedSubscript: "moveLeft" as NSString)
        
        let moveRight: @convention(block) () -> Void = { EditorCallbacks.moveRight?() }
        api.setObject(unsafeBitCast(moveRight, to: AnyObject.self), forKeyedSubscript: "moveRight" as NSString)
        
        let moveHome: @convention(block) () -> Void = { EditorCallbacks.moveHome?() }
        api.setObject(unsafeBitCast(moveHome, to: AnyObject.self), forKeyedSubscript: "moveHome" as NSString)
        
        let moveEnd: @convention(block) () -> Void = { EditorCallbacks.moveEnd?() }
        api.setObject(unsafeBitCast(moveEnd, to: AnyObject.self), forKeyedSubscript: "moveEnd" as NSString)
        
        let pageUp: @convention(block) () -> Void = { EditorCallbacks.pageUp?() }
        api.setObject(unsafeBitCast(pageUp, to: AnyObject.self), forKeyedSubscript: "pageUp" as NSString)
        
        let pageDown: @convention(block) () -> Void = { EditorCallbacks.pageDown?() }
        api.setObject(unsafeBitCast(pageDown, to: AnyObject.self), forKeyedSubscript: "pageDown" as NSString)
        
        // Editing functions
        let save: @convention(block) () -> Void = { EditorCallbacks.save?() }
        api.setObject(unsafeBitCast(save, to: AnyObject.self), forKeyedSubscript: "save" as NSString)
        
        let quit: @convention(block) () -> Void = { EditorCallbacks.quit?() }
        api.setObject(unsafeBitCast(quit, to: AnyObject.self), forKeyedSubscript: "quit" as NSString)
        
        let insertChar: @convention(block) (String) -> Void = { char in EditorCallbacks.insertChar?(char) }
        api.setObject(unsafeBitCast(insertChar, to: AnyObject.self), forKeyedSubscript: "insertChar" as NSString)
        
        let insertText: @convention(block) (String) -> Void = { text in EditorCallbacks.insertText?(text) }
        api.setObject(unsafeBitCast(insertText, to: AnyObject.self), forKeyedSubscript: "insertText" as NSString)
        
        let newline: @convention(block) () -> Void = { EditorCallbacks.newline?() }
        api.setObject(unsafeBitCast(newline, to: AnyObject.self), forKeyedSubscript: "newline" as NSString)
        
        let backspace: @convention(block) () -> Void = { EditorCallbacks.backspace?() }
        api.setObject(unsafeBitCast(backspace, to: AnyObject.self), forKeyedSubscript: "backspace" as NSString)
        
        let deleteChar: @convention(block) () -> Void = { EditorCallbacks.deleteChar?() }
        api.setObject(unsafeBitCast(deleteChar, to: AnyObject.self), forKeyedSubscript: "deleteChar" as NSString)
        
        // S-expression navigation
        let forwardSexp: @convention(block) () -> Void = { EditorCallbacks.forwardSexp?() }
        api.setObject(unsafeBitCast(forwardSexp, to: AnyObject.self), forKeyedSubscript: "forwardSexp" as NSString)
        
        let backwardSexp: @convention(block) () -> Void = { EditorCallbacks.backwardSexp?() }
        api.setObject(unsafeBitCast(backwardSexp, to: AnyObject.self), forKeyedSubscript: "backwardSexp" as NSString)
        
        let gotoMatchingParen: @convention(block) () -> Void = { EditorCallbacks.gotoMatchingParen?() }
        api.setObject(unsafeBitCast(gotoMatchingParen, to: AnyObject.self), forKeyedSubscript: "gotoMatchingParen" as NSString)
        
        let killSexp: @convention(block) () -> Void = { EditorCallbacks.killSexp?() }
        api.setObject(unsafeBitCast(killSexp, to: AnyObject.self), forKeyedSubscript: "killSexp" as NSString)
        
        // Info functions
        let getCursorX: @convention(block) () -> Int = { EditorCallbacks.getCursorX?() ?? 0 }
        api.setObject(unsafeBitCast(getCursorX, to: AnyObject.self), forKeyedSubscript: "getCursorX" as NSString)
        
        let getCursorY: @convention(block) () -> Int = { EditorCallbacks.getCursorY?() ?? 0 }
        api.setObject(unsafeBitCast(getCursorY, to: AnyObject.self), forKeyedSubscript: "getCursorY" as NSString)
        
        let getLineCount: @convention(block) () -> Int = { EditorCallbacks.getLineCount?() ?? 0 }
        api.setObject(unsafeBitCast(getLineCount, to: AnyObject.self), forKeyedSubscript: "getLineCount" as NSString)
        
        let getCurrentLine: @convention(block) () -> String = { EditorCallbacks.getCurrentLine?() ?? "" }
        api.setObject(unsafeBitCast(getCurrentLine, to: AnyObject.self), forKeyedSubscript: "getCurrentLine" as NSString)
        
        let setStatusMessage: @convention(block) (String) -> Void = { msg in EditorCallbacks.setStatusMessage?(msg) }
        api.setObject(unsafeBitCast(setStatusMessage, to: AnyObject.self), forKeyedSubscript: "setStatusMessage" as NSString)
        
        return api
    }
}

