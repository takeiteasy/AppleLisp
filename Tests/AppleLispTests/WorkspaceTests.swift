import XCTest
@testable import AppleLisp

final class WorkspaceTests: AppleLispTestCase {
    func testFileIcon() throws {
        // Get icon of Package.swift
        let iconB64 = try eval("(.fileIcon Workspace \"Package.swift\")")
        XCTAssertNotEqual(iconB64, "nil")
        XCTAssertTrue(iconB64.count > 100) // Should be a decent size string
    }
    
    func testDefaultApp() throws {
        // Check default app for Package.swift (likely Xcode or TextEditor)
        let appPath = try eval("(.defaultApp Workspace \"Package.swift\")")
        XCTAssertNotEqual(appPath, "nil")
        XCTAssertTrue(appPath.contains(".app"))
    }
    
    func testMoveToTrash() throws {
        // Create temp file
        let tempFile = "temp_trash_test.txt"
        _ = try eval("(.writeFile FileManager \"\(tempFile)\" \"garbage\")")
        
        // Trash it
        let res = try eval("(.moveToTrash Workspace \"\(tempFile)\")")
        XCTAssertEqual(res, "true")
        
        // Verify it's gone from original location
        let exists = try eval("(.exists FileManager \"\(tempFile)\")")
        XCTAssertEqual(exists, "false")
    }
    
    func testFullPath() throws {
        // Test deprecated fullPath logic
        // "Terminal" usually resolves
        let term = try eval("(.fullPath Workspace \"Terminal\")")
        // Can be /System/Applications/Utilities/Terminal.app
        XCTAssertTrue(term.contains("Terminal.app"))
    }
}
