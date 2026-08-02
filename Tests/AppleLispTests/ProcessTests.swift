import XCTest
@testable import AppleLisp

final class ProcessTests: AppleLispTestCase {
    func testPid() throws {
        let pid = try eval("(.pid Process)")
        XCTAssertNotEqual(pid, "0")
    }
    
    func testExec() throws {
        // ls -la
        // Let's check status via JS
        let status = try eval("(get (.exec Process \"/bin/ls\") \"status\")")
        XCTAssertEqual(status, "0")
    }
    
    func testSpawnAndKill() throws {
        // Spawn a sleep process
        let pidStr = try eval("(.spawn Process \"/bin/sleep\" [\"10\"])")
        guard let pid = Int(pidStr), pid > 0 else {
            XCTFail("Invalid PID returned: \(pidStr)")
            return
        }
        
        // Kill it
        let killed = try eval("(.kill Process \(pid))")
        XCTAssertEqual(killed, "true")
    }
    
    func testLaunchApp() throws {
        // Just verify the API is callable.
        // We use a fake bundle ID so it should return false (or not crash).
        let result = try eval("(.launchApp Process \"com.fake.app.does.not.exist\")")
        XCTAssertEqual(result, "false")
    }
}