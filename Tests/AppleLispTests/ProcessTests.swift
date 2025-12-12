import XCTest
@testable import AppleLisp

final class ProcessTests: AppleLispTestCase {
    func testPid() throws {
        let pid = try eval("(.pid Process)")
        XCTAssertNotEqual(pid, "0")
    }
    
    func testExec() throws {
        // ls -la
        let res = try eval("(.exec Process \"/bin/ls\" [\"-la\"])")
        // The result is a JS object {status, stdout, stderr}
        // toString() might return [object Object]
        // We need to inspect properties in JS or check return
        
        // Let's check status via JS
        let status = try eval("(get (.exec Process \"/bin/ls\") \"status\")")
        XCTAssertEqual(status, "0")
    }
}

