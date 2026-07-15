import XCTest
@testable import AppleLisp

class AppleLispTestCase: XCTestCase {
    var lisp: AppleLisp!

    override func setUpWithError() throws {
        lisp = try AppleLisp()
    }
    
    override func tearDownWithError() throws {
        lisp = nil
    }
    
    func eval(_ code: String) throws -> String {
        let result = try lisp.evaluate(source: code)
        return result?.toString() ?? "nil"
    }
}