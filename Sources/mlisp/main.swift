import ArgumentParser
import CoreGraphics
import Foundation
import JavaScriptCore
import AppleLisp

@main
struct MLisp: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mlisp",
        abstract: "A keyboard-driven daemon for macOS automation"
    )

    func run() throws {
        // Initialize AppleLisp and register all built-in macOS native APIs
        let lisp = try AppleLisp()
        try lisp.registerAllNativeAPIs()

        // Example: Set up some default bindings
        try lisp.evaluate(source: """
            ;; Register some example bindings
            (.bind KeyBinding "C-x C-c" (fn [] (prn "Quit command received")))
            (.bind KeyBinding "C-x C-f" (fn [] (prn "Find file")))
            (.bind KeyBinding "M-x" (fn [] (prn "Execute extended command")))

            ;; Show partial sequence feedback
            (.onSequenceChange KeyBinding (fn [seq]
              (when seq (prn (str "Waiting: " seq)))))

            ;; Show when sequence is cancelled (by Escape)
            (.onCancel KeyBinding (fn []
              (prn "Sequence cancelled")))
            """)

        // Start the key capture
        let started = try lisp.evaluate(source: "(.start KeyBinding)")

        if started?.toBool() != true {
            throw RuntimeError("Failed to start key capture. Ensure accessibility permissions are granted.")
        }

        print("mlisp running with KeyBinding API.")
        print("Registered bindings:")
        print("  C-x C-c  - Quit command")
        print("  C-x C-f  - Find file")
        print("  M-x      - Execute extended command")
        print("")
        print("Timeout: 0 (wait indefinitely for sequence)")
        print("Press Escape to cancel a pending sequence.")
        print("Press Ctrl+C to exit.")

        // Run the main loop
        CFRunLoopRun()
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}
