import XCTest
@testable import AppleLisp

final class UserDefaultsTests: AppleLispTestCase {
    func testUserDefaults() throws {
        let key = "AppleLispTestKey"
        let val = "testValue"
        
        _ = try eval("(.set UserDefaults \"\(key)\" \"\(val)\")")
        XCTAssertEqual(try eval("(.string UserDefaults \"\(key)\")"), val)
        
        _ = try eval("(.remove UserDefaults \"\(key)\")")
        // Depends on implementation, might return null/undefined
        let res = try eval("(.string UserDefaults \"\(key)\")")
        XCTAssertTrue(res == "undefined" || res == "nil")
    }
}
