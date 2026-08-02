import XCTest
@testable import AppleLisp

final class InputSimulationTests: AppleLispTestCase {
    func testMousePosition() throws {
        // Just check if we can get a position, actual values depend on the machine/CI
        let pos = try eval("(.getMousePosition InputSimulation)")
        // Expected format: {"x": 123, "y": 456} (as string from eval?)
        // Actually eval returns string representation.
        // It might be "[object Object]" or similar if not handled.
        // But our eval helper converts to string.
        // Let's assume the helper returns a description.
        // We can check if it contains x and y.
        // Better: let's use the object properties if we can.
        
        // Actually, our test helper `eval` returns `result?.toString()`.
        // For a dictionary/JSObject, it might just be [object Object].
        // We might need to access properties.
        
        let x = try eval("(get (.getMousePosition InputSimulation) \"x\")")
        XCTAssertNotEqual(x, "undefined")
        XCTAssertNotEqual(x, "nil")
    }
    
    func testScroll() throws {
        // Just ensure it doesn't crash
        _ = try eval("(.scrollInput InputSimulation 10)")
    }
    
    func testDelay() throws {
        let start = Date()
        _ = try eval("(.delayInput InputSimulation 0.1)")
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertTrue(elapsed >= 0.1)
    }
    
    // typeString is hard to test without an input field, but we can run it.
    func testTypeString() throws {
         _ = try eval("(.typeString InputSimulation \"test\")")
    }
}
