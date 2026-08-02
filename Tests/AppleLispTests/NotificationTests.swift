import XCTest
@testable import AppleLisp

final class NotificationTests: AppleLispTestCase {
    func testNotificationAPI() throws {
        // Just verify we can call the methods.
        // Permission will return false/nil if no bundle ID.
        _ = try eval("(.requestPermission Notification)")
        
        // Send simple
        let id = try eval("(.send Notification \"Test Title\" \"Test Body\")")
        // If no bundle ID, it returns "nil". If bundle ID, returns UUID string.
        // We just assert it returns something (string).
        XCTAssertFalse(id.isEmpty)
        
        // Send with options
        let opts = "{\"subtitle\" \"Sub\" \"actions\" [{\"id\" \"act1\" \"title\" \"Action 1\"}]}"
        let id2 = try eval("(.send Notification \"Actionable\" \"Body\" \(opts))")
        XCTAssertFalse(id2.isEmpty)
        
        // Set delegate (just call it)
        _ = try eval("(.setDelegate Notification (fn [act id] (print act)))")
    }
}