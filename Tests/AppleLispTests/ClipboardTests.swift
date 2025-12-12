import XCTest
@testable import AppleLisp

final class ClipboardTests: AppleLispTestCase {
    func testClipboard() throws {
        let testStr = "AppleLispTestString-\(UUID().uuidString)"
        _ = try eval("(.setString Clipboard \"\(testStr)\")")
        XCTAssertEqual(try eval("(.getString Clipboard)"), testStr)
        
        _ = try eval("(.clear Clipboard)")
        XCTAssertEqual(try eval("(.getString Clipboard)"), "undefined") // or "" depending on API
    }
}

