import XCTest
@testable import AppleLisp

final class UIAutomationTests: AppleLispTestCase {
    func testSystemWide() throws {
        // Just verify we can get the system element
        // Use 'get' to access property, (.role ...) tries to call it as a function
        let role = try eval("(get (.system UIAutomation) \"role\")")
        // Role of system wide element is usually "AXSystemWide"
        XCTAssertEqual(role, "AXSystemWide")
    }
    
    func testAttributesAndActions() throws {
        // We can inspect the system element
        let attrs = try eval("(.attributes (.system UIAutomation))")
        XCTAssertTrue(attrs.contains("AXRole"))
        
        let actions = try eval("(.actions (.system UIAutomation))")
        // System wide might not have actions, but it shouldn't crash
        XCTAssertNotEqual(actions, "nil")
    }
    
    // waitFor is hard to test without a changing UI, but we can wait for a static property
    func testWaitFor() throws {
        // Wait for role to be AXSystemWide (immediate success)
        let res = try eval("(.waitFor (.system UIAutomation) \"AXRole\" \"AXSystemWide\" 1.0)")
        XCTAssertEqual(res, "true")
        
        // Wait for something that doesn't exist (timeout)
        let res2 = try eval("(.waitFor (.system UIAutomation) \"AXRole\" \"Invalid\" 0.1)")
        XCTAssertEqual(res2, "false")
    }
}
