import XCTest
@testable import AppleLisp

final class SystemControlTests: AppleLispTestCase {
    func testVolume() throws {
        // Just verify it doesn't crash.
        // Changing volume might be annoying on a dev machine, but let's read it.
        let vol = try eval("(.getVolume SystemControl)")
        XCTAssertNotEqual(vol, "nil")
        
        // We won't test setting volume to avoid startling the user.
    }
    
    func testPreventSleep() throws {
        let id = try eval("(.preventSleep SystemControl \"Running Tests\")")
        XCTAssertNotEqual(id, "nil")
        XCTAssertNotEqual(id, "0")
        
        let success = try eval("(.allowSleep SystemControl \"\(id)\")")
        XCTAssertEqual(success, "true")
    }
}
