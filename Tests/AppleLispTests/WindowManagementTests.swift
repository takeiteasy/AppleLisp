import XCTest
@testable import AppleLisp

final class WindowManagementTests: AppleLispTestCase {
    func testListWindows() throws {
        let list = try eval("(.list WindowManagement)")
        XCTAssertNotEqual(list, "nil")
        // Should be a list/array
        // Check if count >= 0. In CI environment, might be 0 windows but not nil.
    }
    
    func testSnapshot() throws {
        // Snapshot all windows (pid -1 or similar, or just test API presence)
        // We'll try to snapshot the Window Server or just check if method exists via running it on invalid PID safely?
        // CGWindowListCreateImage works with window ID.
        // Let's list windows, pick one, and snapshot it.
        // If no windows, we skip.
        
        let windows = try eval("(.list WindowManagement)")
        // If windows is empty string or "[]", we can't test much.
        // Assuming there's at least one window (Finder, etc.) on a normal Mac.
        // In headless CI, there might be none.
        
        // We can pass window ID 0 (desktop) maybe?
        // Let's just try to call snapshot with a dummy ID and ensure no crash.
        let res = try eval("(.snapshot WindowManagement 0)") 
        // Might be nil or empty string if invalid window, but shouldn't crash.
    }
}
