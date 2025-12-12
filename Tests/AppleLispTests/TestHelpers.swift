import XCTest
@testable import AppleLisp

class AppleLispTestCase: XCTestCase {
    var lisp: AppleLisp!
    
    override func setUpWithError() throws {
        lisp = try AppleLisp()
        
        // Load all native APIs into global scope for tests
        for api in AppleLisp.NativeAPI.allCases {
            // Ensure API is loaded
            _ = lisp.loadAPI(api)
            // Define global variable with the API name (e.g., FileManager)
            // We use __macos_require because it's the internal hook, or just grab from __macos_apis
            let source = "(def \(api.rawValue) (get __macos_apis \"\(api.rawValue)\"))"
            _ = try lisp.evaluate(source: source)
        }
    }
    
    override func tearDownWithError() throws {
        lisp = nil
    }
    
    func eval(_ code: String) throws -> String {
        let result = try lisp.evaluate(source: code)
        return result?.toString() ?? "nil"
    }
}