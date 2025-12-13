import AppleLisp
import Foundation
import CEditline
import ArgumentParser

// MARK: - CLI

@main
struct AppleLispCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "repl",
        abstract: "AppleLisp - Wisp Lisp on JavaScriptCore",
        version: "0.1.0"
    )
    
    @Argument(help: "Wisp files to evaluate")
    var files: [String] = []
    
    @Option(name: .shortAndLong, help: "Evaluate expression")
    var eval: String?
    
    @Flag(name: .shortAndLong, help: "Enter REPL after evaluating files")
    var repl: Bool = false
    
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
        
        // Load config file
        loadConfig(lisp: lisp)
        
        var hadError = false
        
        // Evaluate expression
        if let expr = eval {
            do {
                let result = try lisp.evaluate(source: expr, uri: "<eval>")
                if let result = result, !result.isUndefined {
                    print(result)
                }
            } catch {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                hadError = true
            }
        }
        
        // Evaluate files
        for file in files {
            do {
                guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
                    fputs("Error: Could not read file: \(file)\n", stderr)
                    hadError = true
                    continue
                }
                let result = try lisp.evaluate(source: source, uri: file)
                if let result = result, !result.isUndefined {
                    print(result)
                }
            } catch {
                fputs("Error in \(file): \(error.localizedDescription)\n", stderr)
                hadError = true
            }
        }
        
        // Enter REPL if: no args, --repl flag, or error occurred
        let shouldEnterRepl = (files.isEmpty && eval == nil) || repl || hadError
        
        if shouldEnterRepl {
            if hadError {
                print("\nDropping into REPL due to error...")
            }
            REPL.run(lisp: lisp)
        }
    }
}

// MARK: - REPL

enum REPL {
    static let historyPath = NSString("~/.mlisp_history").expandingTildeInPath
    
    static func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyPath),
              let contents = try? String(contentsOfFile: historyPath, encoding: .utf8) else {
            return
        }
        for line in contents.split(separator: "\n") {
            add_history(strdup(String(line)))
        }
    }
    
    static func saveHistory(_ line: String) {
        let entry = line + "\n"
        if let handle = FileHandle(forWritingAtPath: historyPath) {
            handle.seekToEndOfFile()
            handle.write(entry.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? entry.write(toFile: historyPath, atomically: true, encoding: .utf8)
        }
    }
    
    static func printBanner() {
        print("AppleLisp REPL")
        print("Type :help for commands, :quit to exit")
        print("")
    }
    
    static func printHelp() {
        print("""
        Commands:
          :help     Show this help message
          :quit     Exit the REPL
          :q        Exit the REPL (short)
          :load     Load and evaluate a file
        
        Examples:
          (+ 1 2 3)                    ; arithmetic
          (def x 10)                   ; define variable
          (defn square [x] (* x x))    ; define function
          (map inc [1 2 3])            ; use sequences
        """)
    }
    
    static func run(lisp: AppleLisp) {
        printBanner()
        loadHistory()
        
        while true {
            guard let cline = readline("=> ") else {
                print("")
                break
            }
            
            let line = String(cString: cline)
            free(cline)
            
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)
            if trimmed.isEmpty {
                continue
            }
            
            add_history(strdup(line))
            saveHistory(line)
            
            // Handle commands
            if trimmed.hasPrefix(":") {
                let parts = trimmed.split(separator: " ", maxSplits: 1)
                let cmd = String(parts[0]).lowercased()
                let arg = parts.count > 1 ? String(parts[1]) : nil
                
                switch cmd {
                case ":quit", ":q":
                    print("Goodbye!")
                    return
                case ":help":
                    printHelp()
                case ":load":
                    if let file = arg {
                        do {
                            guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
                                print("Could not read file: \(file)")
                                continue
                            }
                            let result = try lisp.evaluate(source: source, uri: file)
                            if let result = result, !result.isUndefined {
                                print(result)
                            }
                        } catch {
                            fputs("Error: \(error.localizedDescription)\n", stderr)
                        }
                    } else {
                        print("Usage: :load <filename>")
                    }
                default:
                    print("Unknown command: \(cmd)")
                }
                continue
            }
            
            // Evaluate Wisp code
            do {
                let result = try lisp.evaluate(source: line)
                if let result = result, !result.isUndefined {
                    print(result)
                }
            } catch {
                fputs("Error: \(error.localizedDescription)\n", stderr)
            }
        }
    }
}

// MARK: - Config Loading

extension AppleLispCLI {
    func loadConfig(lisp: AppleLisp) {
        let fm = FileManager.default
        var configPath: String?
        
        if let userConfig = config {
            configPath = userConfig
        } else {
            // Check default paths: ./.mlisp then ~/.mlisp
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
