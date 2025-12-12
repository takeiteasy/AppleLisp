import XCTest
@testable import AppleLisp

final class FileManagerTests: AppleLispTestCase {
    func testFileExists() throws {
        // We know Package.swift exists
        XCTAssertEqual(try eval("(.exists FileManager \"Package.swift\")"), "true")
        XCTAssertEqual(try eval("(.exists FileManager \"NonExistentFile.txt\")"), "false")
    }
    
    func testReadFile() throws {
        let content = try eval("(.readFile FileManager \"Package.swift\")")
        XCTAssertTrue(content.contains("package"))
    }
    
    func testCurrentDirectory() throws {
        let dir = try eval("(.currentDirectory FileManager)")
        XCTAssertFalse(dir.isEmpty)
    }
}
