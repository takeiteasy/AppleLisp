import XCTest
@testable import AppleLisp

final class ScriptingBridgeTests: AppleLispTestCase {
    func testRecursiveWrapping() throws {
        #if !os(macOS)
        return
        #endif
        
        // 1. Test Single Object Recursive Wrapping
        // Use "startupDisk" which should have a name like "Macintosh HD"
        let code = """
        (let [finder (Application.create "com.apple.finder")]
             (if finder
                 (let [disk (.property finder "startupDisk")]
                      ;; Check if we can get property of the wrapped disk object
                      (.property disk "name"))
                 "finder-not-found"))
        """
        
        let result = try eval(code)
        print("ScriptingBridge .property Result: '\(result)'")
        XCTAssertFalse(result.isEmpty, "Result should not be empty")
        XCTAssertNotEqual(result, "undefined")
        XCTAssertNotEqual(result, "nil")
        
        // 2. Test Array Wrapping
        // "windows" returns SBElementArray. We map it to JS Array of SBObjectWrappers.
        // Even if empty, it should be an array.
        let codeArray = """
        (let [finder (Application.create "com.apple.finder")]
             (if finder
                 (let [windows (.property finder "windows")]
                      ;; Check if it is an array
                      (if (.isArray Array windows)
                          "is-array"
                          "not-array"))
                 "finder-not-found"))
        """
        
        let resultArray = try eval(codeArray)
        print("ScriptingBridge Array Result: '\(resultArray)'")
        XCTAssertEqual(resultArray, "is-array")
    }
}
