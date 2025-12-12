import AppleLisp
import Foundation
import ArgumentParser

struct AppleLispEditor: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "editor",
        abstract: "AppleLisp Editor - A simple Wisp editor",
        version: "0.1.0"
    )
    
    @Argument(help: "File to edit")
    var file: String?
    
    @Option(name: .shortAndLong, help: "Config file to load (default: ~/.mlisp or ./.mlisp)")
    var config: String?
    
    mutating func run() throws {
        let lisp: AppleLisp
        do {
            lisp = try AppleLisp()
        } catch {
            fputs("Error: Failed to initialize AppleLisp: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
        
        let editor = Editor()
        
        // Wire up KeyMapCallbacks
        KeyMapCallbacks.bind = { seqStr, action in
            guard let seq = KeyMapAPI.parseKeySequence(seqStr) else {
                print("[KeyMap] Invalid key sequence: \(seqStr)")
                return false
            }
            editor.keyMap.bind(seq, name: seqStr, to: action)
            return true
        }
        KeyMapCallbacks.unbind = { seqStr in
            guard let seq = KeyMapAPI.parseKeySequence(seqStr) else { return false }
            if let combo = seq.combos.first, seq.combos.count == 1 {
                editor.keyMap.unbind(combo)
            }
            return true
        }
        KeyMapCallbacks.list = {
            editor.keyMap.allBindings.compactMap { $0.name }
        }
        KeyMapCallbacks.debug = { enable in
            editor.debugKeyBindings = enable
        }
        
        // Wire up EditorCallbacks
        EditorCallbacks.moveUp = { editor.moveUpPublic() }
        EditorCallbacks.moveDown = { editor.moveDownPublic() }
        EditorCallbacks.moveLeft = { editor.moveLeftPublic() }
        EditorCallbacks.moveRight = { editor.moveRightPublic() }
        EditorCallbacks.moveHome = { editor.moveHomePublic() }
        EditorCallbacks.moveEnd = { editor.moveEndPublic() }
        EditorCallbacks.pageUp = { editor.pageUpPublic() }
        EditorCallbacks.pageDown = { editor.pageDownPublic() }
        EditorCallbacks.save = { editor.savePublic() }
        EditorCallbacks.quit = { editor.quitPublic() }
        EditorCallbacks.insertChar = { char in
            if let c = char.first { editor.insertCharPublic(c) }
        }
        EditorCallbacks.insertText = { editor.insertTextPublic($0) }
        EditorCallbacks.newline = { editor.insertNewlinePublic() }
        EditorCallbacks.backspace = { editor.backspacePublic() }
        EditorCallbacks.deleteChar = { editor.deleteCharPublic() }
        
        // S-expression navigation
        EditorCallbacks.forwardSexp = { editor.forwardSexpPublic() }
        EditorCallbacks.backwardSexp = { editor.backwardSexpPublic() }
        EditorCallbacks.gotoMatchingParen = { editor.gotoMatchingParenPublic() }
        EditorCallbacks.killSexp = { editor.killSexpPublic() }
        
        EditorCallbacks.getCursorX = { editor.cursorXPublic }
        EditorCallbacks.getCursorY = { editor.cursorYPublic }
        EditorCallbacks.getLineCount = { editor.lineCountPublic }
        EditorCallbacks.getCurrentLine = { editor.currentLinePublic }
        EditorCallbacks.setStatusMessage = { editor.setStatusMessagePublic($0) }
        
        // Register APIs
        lisp.registerCustomAPI(name: "KeyMap", value: KeyMapAPI.install(in: lisp.jsContext))
        lisp.registerCustomAPI(name: "Editor", value: EditorAPI.install(in: lisp.jsContext))
        lisp.registerCustomAPI(name: "Hooks", value: HooksAPI.install(in: lisp.jsContext))
        
        // Load config
        loadConfig(lisp: lisp)
        
        // Run after-init-hook
        Hooks.shared.run(HookNames.afterInit)
        
        editor.open(file: file)
    }
    
    func loadConfig(lisp: AppleLisp) {
        let fm = FileManager.default
        var configPath: String?
        
        if let userConfig = config {
            configPath = userConfig
        } else {
            let localConfig = "./.mlisp"
            let homeConfig = NSString("~/.mlisp").expandingTildeInPath
            
            if fm.fileExists(atPath: localConfig) {
                configPath = localConfig
            } else if fm.fileExists(atPath: homeConfig) {
                configPath = homeConfig
            }
        }
        
        guard let path = configPath else { return }
        
        guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
            fputs("Warning: Could not read config file: \(path)\n", stderr)
            return
        }
        
        do {
            try lisp.evaluate(source: source, uri: path)
        } catch {
            fputs("Warning: Config error in \(path): \(error.localizedDescription)\n", stderr)
        }
    }
}

AppleLispEditor.main()