import Foundation
import CNcurses
import AppleLisp

/// Simple ncurses-based text editor with Wisp syntax highlighting
public class Editor {
    private var lines: [String] = [""]
    private var cursorX: Int = 0
    private var cursorY: Int = 0
    private var scrollY: Int = 0
    private var filename: String?
    private var modified: Bool = false
    private var running: Bool = true
    private var statusMessage: String = ""
    public var debugKeyBindings: Bool = false
    
    public let keyMap: KeyMap
    
    // Syntax highlighting colors
    private static let colorNormal: Int16 = 1
    private static let colorKeyword: Int16 = 2
    private static let colorString: Int16 = 3
    private static let colorComment: Int16 = 4
    private static let colorNumber: Int16 = 5
    private static let colorParen: Int16 = 6
    private static let colorBuiltin: Int16 = 7
    
    // Wisp keywords
    private static let keywords: Set<String> = [
        "def", "defn", "defmacro", "fn", "let", "if", "do", "cond",
        "loop", "recur", "quote", "unquote", "try", "catch", "throw",
        "ns", "require", "import", "export", "set!"
    ]
    
    private static let builtins: Set<String> = [
        "map", "filter", "reduce", "cons", "first", "rest", "nth",
        "count", "empty?", "nil?", "list", "vector", "hash-map",
        "get", "assoc", "dissoc", "keys", "vals", "merge",
        "str", "print", "println", "pr", "prn", "read-string",
        "+", "-", "*", "/", "=", "<", ">", "<=", ">=", "not", "and", "or",
        "inc", "dec", "true", "false", "nil"
    ]
    
    // Kill ring for cut/paste
    private var killRing: [String] = []
    private var killRingIndex: Int = 0
    private let maxKillRingSize = 60
    
    public init(keyMap: KeyMap = KeyMap()) {
        self.keyMap = keyMap
        setupDefaultBindings()
    }
    
    private func setupDefaultBindings() {
        // Emacs navigation
        keyMap.bindCtrl("A", name: "beginning-of-line") { [weak self] in self?.moveHome() }
        keyMap.bindCtrl("E", name: "end-of-line") { [weak self] in self?.moveEnd() }
        keyMap.bindCtrl("F", name: "forward-char") { [weak self] in self?.moveRight() }
        keyMap.bindCtrl("B", name: "backward-char") { [weak self] in self?.moveLeft() }
        keyMap.bindCtrl("N", name: "next-line") { [weak self] in self?.moveDown() }
        keyMap.bindCtrl("P", name: "previous-line") { [weak self] in self?.moveUp() }
        
        // Emacs editing
        keyMap.bindCtrl("K", name: "kill-line") { [weak self] in self?.killLine() }
        keyMap.bindCtrl("Y", name: "yank") { [weak self] in self?.yank() }
        keyMap.bindCtrl("D", name: "delete-char") { [weak self] in self?.deleteChar() }
        keyMap.bindCtrl("G", name: "keyboard-quit") { [weak self] in self?.keyboardQuit() }
        
        // S-expression navigation (Alt/Meta key bindings)
        keyMap.bind(KeyCombo(Int32(Character("]").asciiValue!), modifiers: .ctrl), 
                    name: "goto-matching-paren") { [weak self] in self?.gotoMatchingParen() }
        keyMap.bind(KeyCombo(27), name: "meta-prefix") { [weak self] in 
            // Escape as Meta prefix - next key gets meta modifier
            self?.statusMessage = "M-"
        }
        
        // C-x prefix commands
        keyMap.bindSequence(.ctrl("X"), .ctrl("S"), name: "save-buffer") { [weak self] in self?.save() }
        keyMap.bindSequence(.ctrl("X"), .ctrl("C"), name: "exit") { [weak self] in self?.quit() }
        keyMap.bindSequence(.ctrl("X"), .ctrl("F"), name: "find-file") { [weak self] in 
            self?.statusMessage = "find-file: not implemented (use :edit in REPL)"
        }
        
        // Special keys
        keyMap.bind(KeyCombo(SpecialKey.home), name: "home") { [weak self] in self?.moveHome() }
        keyMap.bind(KeyCombo(SpecialKey.end), name: "end") { [weak self] in self?.moveEnd() }
        keyMap.bind(KeyCombo(SpecialKey.pageUp), name: "page-up") { [weak self] in self?.pageUp() }
        keyMap.bind(KeyCombo(SpecialKey.pageDown), name: "page-down") { [weak self] in self?.pageDown() }
    }
    
    /// Open editor, optionally with a file
    public func open(file: String? = nil) {
        if let file = file {
            loadFile(file)
        }
        
        initScreen()
        defer { endScreen() }
        
        while running {
            render()
            handleInput()
        }
    }
    
    private func loadFile(_ path: String) {
        filename = path
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            lines = content.components(separatedBy: "\n")
            if lines.isEmpty { lines = [""] }
        } else {
            lines = [""]
        }
        modified = false
        
        // Run after-open-hook
        Hooks.shared.run(HookNames.afterOpen)
    }
    
    private func initScreen() {
        initscr()
        raw()
        noecho()
        keypad(stdscr, true)
        
        if has_colors() {
            start_color()
            use_default_colors()
            init_pair(Editor.colorNormal, Int16(COLOR_WHITE), -1)
            init_pair(Editor.colorKeyword, Int16(COLOR_MAGENTA), -1)
            init_pair(Editor.colorString, Int16(COLOR_GREEN), -1)
            init_pair(Editor.colorComment, Int16(COLOR_CYAN), -1)
            init_pair(Editor.colorNumber, Int16(COLOR_YELLOW), -1)
            init_pair(Editor.colorParen, Int16(COLOR_BLUE), -1)
            init_pair(Editor.colorBuiltin, Int16(COLOR_RED), -1)
        }
    }
    
    private func endScreen() {
        endwin()
    }
    
    private func render() {
        erase()
        
        let height = Int(LINES) - 2  // Leave room for status bar
        let width = Int(COLS)
        
        // Render lines with syntax highlighting
        for row in 0..<height {
            let lineIdx = scrollY + row
            if lineIdx < lines.count {
                renderLine(lines[lineIdx], row: row, width: width)
            }
        }
        
        // Status bar
        renderStatusBar(row: Int(LINES) - 2)
        
        // Message bar
        if !statusMessage.isEmpty {
            mvaddstr(Int32(LINES) - 1, 0, statusMessage)
        }
        
        // Position cursor
        let screenCursorY = cursorY - scrollY
        CNcurses.move(Int32(screenCursorY), Int32(cursorX))
        
        refresh()
    }
    
    private func renderLine(_ line: String, row: Int, width: Int) {
        let chars = Array(line)
        var col = 0
        var i = 0
        
        while i < chars.count && col < width {
            let char = chars[i]
            
            // Comment
            if char == ";" {
                attron(COLOR_PAIR(Int32(Editor.colorComment)))
                while i < chars.count && col < width {
                    mvaddch(Int32(row), Int32(col), UInt32(chars[i].asciiValue ?? 0))
                    i += 1
                    col += 1
                }
                attroff(COLOR_PAIR(Int32(Editor.colorComment)))
                break
            }
            
            // String
            if char == "\"" {
                attron(COLOR_PAIR(Int32(Editor.colorString)))
                mvaddch(Int32(row), Int32(col), UInt32(char.asciiValue ?? 0))
                i += 1
                col += 1
                while i < chars.count && col < width {
                    let c = chars[i]
                    mvaddch(Int32(row), Int32(col), UInt32(c.asciiValue ?? 0))
                    i += 1
                    col += 1
                    if c == "\"" && (i < 2 || chars[i-2] != "\\") { break }
                }
                attroff(COLOR_PAIR(Int32(Editor.colorString)))
                continue
            }
            
            // Parentheses
            if char == "(" || char == ")" || char == "[" || char == "]" || char == "{" || char == "}" {
                attron(COLOR_PAIR(Int32(Editor.colorParen)) | ATTR_BOLD)
                mvaddch(Int32(row), Int32(col), UInt32(char.asciiValue ?? 0))
                attroff(COLOR_PAIR(Int32(Editor.colorParen)) | ATTR_BOLD)
                i += 1
                col += 1
                continue
            }
            
            // Number
            if char.isNumber || (char == "-" && i + 1 < chars.count && chars[i+1].isNumber) {
                attron(COLOR_PAIR(Int32(Editor.colorNumber)))
                while i < chars.count && col < width && (chars[i].isNumber || chars[i] == "." || chars[i] == "-") {
                    mvaddch(Int32(row), Int32(col), UInt32(chars[i].asciiValue ?? 0))
                    i += 1
                    col += 1
                }
                attroff(COLOR_PAIR(Int32(Editor.colorNumber)))
                continue
            }
            
            // Word (potential keyword/builtin)
            if char.isLetter || char == "-" || char == "_" || char == "?" || char == "!" || char == "*" || char == "+" {
                var word = ""
                let startCol = col
                while i < chars.count && isWordChar(chars[i]) {
                    word.append(chars[i])
                    i += 1
                }
                
                let color: Int16
                if Editor.keywords.contains(word) {
                    color = Editor.colorKeyword
                } else if Editor.builtins.contains(word) {
                    color = Editor.colorBuiltin
                } else {
                    color = Editor.colorNormal
                }
                
                attron(COLOR_PAIR(Int32(color)))
                for (j, c) in word.enumerated() {
                    if startCol + j < width {
                        mvaddch(Int32(row), Int32(startCol + j), UInt32(c.asciiValue ?? 0))
                    }
                }
                attroff(COLOR_PAIR(Int32(color)))
                col = startCol + word.count
                continue
            }
            
            // Default character
            mvaddch(Int32(row), Int32(col), UInt32(char.asciiValue ?? 0))
            i += 1
            col += 1
        }
    }
    
    private func isWordChar(_ c: Character) -> Bool {
        c.isLetter || c.isNumber || c == "-" || c == "_" || c == "?" || c == "!" || c == "*" || c == "+" || c == "/" || c == "<" || c == ">" || c == "="
    }
    
    private func renderStatusBar(row: Int) {
        attron(ATTR_REVERSE)
        
        let name = filename ?? "[New File]"
        let modMark = modified ? " [+]" : ""
        let left = " \(name)\(modMark)"
        let right = "Ln \(cursorY + 1), Col \(cursorX + 1) "
        
        var bar = left
        let padding = Int(COLS) - left.count - right.count
        if padding > 0 {
            bar += String(repeating: " ", count: padding)
        }
        bar += right
        
        mvaddstr(Int32(row), 0, String(bar.prefix(Int(COLS))))
        
        attroff(ATTR_REVERSE)
    }
    
    private func handleInput() {
        let ch = getch()
        
        // Debug output
        if debugKeyBindings {
            let bindingCount = keyMap.allBindings.count
            statusMessage = "[DEBUG] Key: \(ch) | Bindings: \(bindingCount)"
        }
        
        // Try keymap first
        if keyMap.handle(ch) {
            // Show pending prefix if waiting for more keys
            if keyMap.hasPending {
                statusMessage = keyMap.pendingPrefix + "-"
            } else if debugKeyBindings {
                statusMessage += " | HANDLED by keymap"
            } else {
                statusMessage = ""
            }
            return
        }
        
        if !debugKeyBindings {
            statusMessage = ""
        }
        
        switch ch {
        case SpecialKey.up:
            moveUp()
        case SpecialKey.down:
            moveDown()
        case SpecialKey.left:
            moveLeft()
        case SpecialKey.right:
            moveRight()
        case SpecialKey.backspace, 127:
            backspace()
        case SpecialKey.delete:
            deleteChar()
        case SpecialKey.enter:
            insertNewline()
        case SpecialKey.tab:
            insertText("  ")
        case 27:  // Escape
            break
        default:
            if ch >= 32 && ch < 127 {
                insertChar(Character(UnicodeScalar(UInt8(ch))))
            }
        }
    }
    
    // MARK: - Movement
    
    private func moveUp() {
        if cursorY > 0 {
            cursorY -= 1
            clampCursorX()
            scrollIfNeeded()
        }
    }
    
    private func moveDown() {
        if cursorY < lines.count - 1 {
            cursorY += 1
            clampCursorX()
            scrollIfNeeded()
        }
    }
    
    private func moveLeft() {
        if cursorX > 0 {
            cursorX -= 1
        } else if cursorY > 0 {
            cursorY -= 1
            cursorX = lines[cursorY].count
            scrollIfNeeded()
        }
    }
    
    private func moveRight() {
        if cursorX < lines[cursorY].count {
            cursorX += 1
        } else if cursorY < lines.count - 1 {
            cursorY += 1
            cursorX = 0
            scrollIfNeeded()
        }
    }
    
    private func moveHome() {
        cursorX = 0
    }
    
    private func moveEnd() {
        cursorX = lines[cursorY].count
    }
    
    private func pageUp() {
        let height = Int(LINES) - 2
        cursorY = max(0, cursorY - height)
        scrollY = max(0, scrollY - height)
        clampCursorX()
    }
    
    private func pageDown() {
        let height = Int(LINES) - 2
        cursorY = min(lines.count - 1, cursorY + height)
        scrollY = min(max(0, lines.count - height), scrollY + height)
        clampCursorX()
    }
    
    private func clampCursorX() {
        cursorX = min(cursorX, lines[cursorY].count)
    }
    
    private func scrollIfNeeded() {
        let height = Int(LINES) - 2
        if cursorY < scrollY {
            scrollY = cursorY
        } else if cursorY >= scrollY + height {
            scrollY = cursorY - height + 1
        }
    }
    
    // MARK: - S-expression Navigation
    
    /// Find matching paren, bracket, or brace at cursor
    private func findMatchingParen() -> (line: Int, col: Int)? {
        guard cursorY < lines.count else { return nil }
        let line = lines[cursorY]
        guard cursorX < line.count else { return nil }
        
        let idx = line.index(line.startIndex, offsetBy: cursorX)
        let char = line[idx]
        
        let pairs: [(open: Character, close: Character)] = [
            ("(", ")"), ("[", "]"), ("{", "}")
        ]
        
        // Check if we're on an opening paren
        if let pair = pairs.first(where: { $0.open == char }) {
            return findForward(open: pair.open, close: pair.close)
        }
        
        // Check if we're on a closing paren
        if let pair = pairs.first(where: { $0.close == char }) {
            return findBackward(open: pair.open, close: pair.close)
        }
        
        return nil
    }
    
    private func findForward(open: Character, close: Character) -> (Int, Int)? {
        var depth = 1
        var y = cursorY
        var x = cursorX + 1
        
        while y < lines.count {
            let line = lines[y]
            while x < line.count {
                let idx = line.index(line.startIndex, offsetBy: x)
                let c = line[idx]
                if c == open { depth += 1 }
                else if c == close { depth -= 1 }
                if depth == 0 { return (y, x) }
                x += 1
            }
            y += 1
            x = 0
        }
        return nil
    }
    
    private func findBackward(open: Character, close: Character) -> (Int, Int)? {
        var depth = 1
        var y = cursorY
        var x = cursorX - 1
        
        while y >= 0 {
            let line = lines[y]
            if x < 0 { x = line.count - 1 }
            while x >= 0 {
                let idx = line.index(line.startIndex, offsetBy: x)
                let c = line[idx]
                if c == close { depth += 1 }
                else if c == open { depth -= 1 }
                if depth == 0 { return (y, x) }
                x -= 1
            }
            y -= 1
            x = y >= 0 ? lines[y].count - 1 : -1
        }
        return nil
    }
    
    /// Move to matching paren
    private func gotoMatchingParen() {
        if let (y, x) = findMatchingParen() {
            cursorY = y
            cursorX = x
            scrollIfNeeded()
        } else {
            statusMessage = "No matching paren"
        }
    }
    
    /// Move forward one s-expression
    private func forwardSexp() {
        guard cursorY < lines.count else { return }
        let line = lines[cursorY]
        
        // Skip whitespace
        var x = cursorX
        var y = cursorY
        while y < lines.count {
            let l = lines[y]
            while x < l.count {
                let idx = l.index(l.startIndex, offsetBy: x)
                if !l[idx].isWhitespace { break }
                x += 1
            }
            if x < l.count { break }
            y += 1
            x = 0
        }
        if y >= lines.count { return }
        
        let l = lines[y]
        let idx = l.index(l.startIndex, offsetBy: x)
        let c = l[idx]
        
        // If on opening paren, jump to matching
        if c == "(" || c == "[" || c == "{" {
            cursorY = y
            cursorX = x
            if let (ny, nx) = findMatchingParen() {
                cursorY = ny
                cursorX = nx + 1
            }
        } else {
            // Move past symbol/word
            while x < l.count {
                let idx = l.index(l.startIndex, offsetBy: x)
                let c = l[idx]
                if c.isWhitespace || c == ")" || c == "]" || c == "}" { break }
                x += 1
            }
            cursorY = y
            cursorX = x
        }
        scrollIfNeeded()
    }
    
    /// Move backward one s-expression 
    private func backwardSexp() {
        // Skip whitespace backward
        var x = cursorX - 1
        var y = cursorY
        while y >= 0 {
            let l = lines[y]
            if x < 0 { x = l.count - 1 }
            while x >= 0 {
                let idx = l.index(l.startIndex, offsetBy: x)
                if !l[idx].isWhitespace { break }
                x -= 1
            }
            if x >= 0 { break }
            y -= 1
            x = y >= 0 ? lines[y].count - 1 : -1
        }
        if y < 0 { return }
        
        let l = lines[y]
        let idx = l.index(l.startIndex, offsetBy: x)
        let c = l[idx]
        
        // If on closing paren, jump to matching
        if c == ")" || c == "]" || c == "}" {
            cursorY = y
            cursorX = x
            if let (ny, nx) = findMatchingParen() {
                cursorY = ny
                cursorX = nx
            }
        } else {
            // Move to start of symbol/word
            while x > 0 {
                let prevIdx = l.index(l.startIndex, offsetBy: x - 1)
                let pc = l[prevIdx]
                if pc.isWhitespace || pc == "(" || pc == "[" || pc == "{" { break }
                x -= 1
            }
            cursorY = y
            cursorX = x
        }
        scrollIfNeeded()
    }
    
    /// Kill (cut) the s-expression at cursor
    private func killSexp() {
        let startY = cursorY
        let startX = cursorX
        forwardSexp()
        if cursorY != startY || cursorX != startX {
            // Kill from start to current position
            let killed = extractText(fromY: startY, fromX: startX, toY: cursorY, toX: cursorX)
            deleteRange(fromY: startY, fromX: startX, toY: cursorY, toX: cursorX)
            pushKillRing(killed)
            cursorY = startY
            cursorX = startX
            modified = true
        }
    }
    
    private func extractText(fromY: Int, fromX: Int, toY: Int, toX: Int) -> String {
        if fromY == toY {
            let line = lines[fromY]
            let start = line.index(line.startIndex, offsetBy: fromX)
            let end = line.index(line.startIndex, offsetBy: toX)
            return String(line[start..<end])
        }
        
        var result = ""
        for y in fromY...toY {
            let line = lines[y]
            if y == fromY {
                let start = line.index(line.startIndex, offsetBy: fromX)
                result += String(line[start...]) + "\n"
            } else if y == toY {
                let end = line.index(line.startIndex, offsetBy: toX)
                result += String(line[..<end])
            } else {
                result += line + "\n"
            }
        }
        return result
    }
    
    private func deleteRange(fromY: Int, fromX: Int, toY: Int, toX: Int) {
        if fromY == toY {
            var line = lines[fromY]
            let start = line.index(line.startIndex, offsetBy: fromX)
            let end = line.index(line.startIndex, offsetBy: toX)
            line.removeSubrange(start..<end)
            lines[fromY] = line
        } else {
            let firstLine = lines[fromY]
            let lastLine = lines[toY]
            let start = firstLine.index(firstLine.startIndex, offsetBy: fromX)
            let end = lastLine.index(lastLine.startIndex, offsetBy: toX)
            lines[fromY] = String(firstLine[..<start]) + String(lastLine[end...])
            lines.removeSubrange((fromY + 1)...toY)
        }
    }
    
    // MARK: - Editing
    
    private func insertChar(_ char: Character) {
        var line = lines[cursorY]
        let idx = line.index(line.startIndex, offsetBy: cursorX)
        line.insert(char, at: idx)
        lines[cursorY] = line
        cursorX += 1
        modified = true
    }
    
    private func insertText(_ text: String) {
        for char in text {
            insertChar(char)
        }
    }
    
    private func insertNewline() {
        let line = lines[cursorY]
        let idx = line.index(line.startIndex, offsetBy: cursorX)
        let before = String(line[..<idx])
        let after = String(line[idx...])
        lines[cursorY] = before
        lines.insert(after, at: cursorY + 1)
        cursorY += 1
        cursorX = 0
        modified = true
        scrollIfNeeded()
    }
    
    private func backspace() {
        if cursorX > 0 {
            var line = lines[cursorY]
            let idx = line.index(line.startIndex, offsetBy: cursorX - 1)
            line.remove(at: idx)
            lines[cursorY] = line
            cursorX -= 1
            modified = true
        } else if cursorY > 0 {
            let line = lines.remove(at: cursorY)
            cursorY -= 1
            cursorX = lines[cursorY].count
            lines[cursorY] += line
            modified = true
            scrollIfNeeded()
        }
    }
    
    private func deleteChar() {
        if cursorX < lines[cursorY].count {
            var line = lines[cursorY]
            let idx = line.index(line.startIndex, offsetBy: cursorX)
            line.remove(at: idx)
            lines[cursorY] = line
            modified = true
        } else if cursorY < lines.count - 1 {
            lines[cursorY] += lines.remove(at: cursorY + 1)
            modified = true
        }
    }
    
    // MARK: - Commands
    
    private func save() {
        guard let filename = filename else {
            statusMessage = "No filename. Use Ctrl+G to set filename."
            return
        }
        
        // Run before-save-hook
        Hooks.shared.run(HookNames.beforeSave)
        
        let content = lines.joined(separator: "\n")
        do {
            try content.write(toFile: filename, atomically: true, encoding: .utf8)
            modified = false
            statusMessage = "Saved: \(filename)"
            
            // Run after-save-hook
            Hooks.shared.run(HookNames.afterSave)
        } catch {
            statusMessage = "Error saving: \(error.localizedDescription)"
        }
    }
    
    private func quit() {
        // Run before-quit-hook
        Hooks.shared.run(HookNames.beforeQuit)
        
        if modified {
            statusMessage = "Unsaved changes! C-x C-c again to quit, C-x C-s to save."
            // Rebind for confirmed quit
            keyMap.bindSequence(.ctrl("X"), .ctrl("C"), name: "exit") { [weak self] in
                self?.running = false
            }
        } else {
            running = false
        }
    }
    
    private func killLine() {
        let line = lines[cursorY]
        if cursorX < line.count {
            // Kill from cursor to end of line
            let idx = line.index(line.startIndex, offsetBy: cursorX)
            let killed = String(line[idx...])
            lines[cursorY] = String(line[..<idx])
            pushKillRing(killed)
            modified = true
        } else if cursorY < lines.count - 1 {
            // Kill newline - join with next line
            let killed = "\n"
            lines[cursorY] += lines.remove(at: cursorY + 1)
            pushKillRing(killed)
            modified = true
        }
    }
    
    private func yank() {
        guard !killRing.isEmpty else {
            statusMessage = "Kill ring is empty"
            return
        }
        let text = killRing[killRingIndex]
        insertText(text)
    }
    
    private func pushKillRing(_ text: String) {
        killRing.insert(text, at: 0)
        if killRing.count > maxKillRingSize {
            killRing.removeLast()
        }
        killRingIndex = 0
    }
    
    private func keyboardQuit() {
        keyMap.cancelPending()
        statusMessage = "Quit"
    }
    
    /// Get the current buffer content
    public var content: String {
        lines.joined(separator: "\n")
    }
    
    // MARK: - Public API wrappers for EditorAPI
    
    public func moveUpPublic() { moveUp() }
    public func moveDownPublic() { moveDown() }
    public func moveLeftPublic() { moveLeft() }
    public func moveRightPublic() { moveRight() }
    public func moveHomePublic() { moveHome() }
    public func moveEndPublic() { moveEnd() }
    public func pageUpPublic() { pageUp() }
    public func pageDownPublic() { pageDown() }
    public func savePublic() { save() }
    public func quitPublic() { quit() }
    public func insertCharPublic(_ char: Character) { insertChar(char) }
    public func insertTextPublic(_ text: String) { insertText(text) }
    public func insertNewlinePublic() { insertNewline() }
    public func backspacePublic() { backspace() }
    public func deleteCharPublic() { deleteChar() }
    
    // S-expression navigation
    public func forwardSexpPublic() { forwardSexp() }
    public func backwardSexpPublic() { backwardSexp() }
    public func gotoMatchingParenPublic() { gotoMatchingParen() }
    public func killSexpPublic() { killSexp() }
    
    public var cursorXPublic: Int { cursorX }
    public var cursorYPublic: Int { cursorY }
    public var lineCountPublic: Int { lines.count }
    public var currentLinePublic: String { lines[cursorY] }
    
    public func setStatusMessagePublic(_ msg: String) {
        statusMessage = msg
    }
}

