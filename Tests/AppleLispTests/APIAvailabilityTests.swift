import XCTest
@testable import AppleLisp

final class APIAvailabilityTests: AppleLispTestCase {
    func testAllAPIsLoad() throws {
        let apis = [
            "FileManager",
            "Process",
            "UserDefaults",
            "Workspace",
            "Clipboard",
            "Interaction",
            "Application",
            "Notification",
            "UIAutomation",
            "InputSimulation",
            "SystemControl",
            "WindowManagement"
        ]
        
        for api in apis {
            let result = try eval("(if \(api) \"loaded\" \"failed\")")
            XCTAssertEqual(result, "loaded", "API \(api) failed to load")
        }
    }
}
