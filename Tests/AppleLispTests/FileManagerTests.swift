import XCTest
@testable import AppleLisp

final class FileManagerTests: AppleLispTestCase {
    func testFileExists() throws {
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
    
    func testAttributesAndPermissions() throws {
        // Create a temp file
        let tempFile = "temp_test_attrs.txt"
        _ = try eval("(.writeFile FileManager \"\(tempFile)\" \"data\")")
        
        // Check attributes
        let size = try eval("(get (.getAttributes FileManager \"\(tempFile)\") \"size\")")
        XCTAssertEqual(size, "4")
        
        let perms = try eval("(get (.getAttributes FileManager \"\(tempFile)\") \"permissions\")")
        XCTAssertNotEqual(perms, "undefined")
        XCTAssertNotEqual(perms, "nil")
        
        // Set permissions to 777 (decimal 511)
        _ = try eval("(.setPermissions FileManager \"\(tempFile)\" 511)")
        
        let newPerms = try eval("(get (.getAttributes FileManager \"\(tempFile)\") \"permissions\")")
        XCTAssertEqual(newPerms, "511")
        
        _ = try eval("(.remove FileManager \"\(tempFile)\")")
    }
    
    func testExtendedAttributes() throws {
        let tempFile = "temp_test_xattr.txt"
        _ = try eval("(.writeFile FileManager \"\(tempFile)\" \"data\")")
        
        let key = "com.applelisp.test"
        let val = "helloworld"
        
        // Set
        _ = try eval("(.setXAttr FileManager \"\(tempFile)\" \"\(key)\" \"\(val)\")")
        
        // Get
        let readVal = try eval("(.getXAttr FileManager \"\(tempFile)\" \"\(key)\")")
        XCTAssertEqual(readVal, val)
        
        // List
        let list = try eval("(.listXAttrs FileManager \"\(tempFile)\")")
        XCTAssertTrue(list.contains(key))
        
        // Remove
        _ = try eval("(.removeXAttr FileManager \"\(tempFile)\" \"\(key)\")")
        let removedVal = try eval("(.getXAttr FileManager \"\(tempFile)\" \"\(key)\")")
        XCTAssertTrue(removedVal == "nil" || removedVal == "undefined")
        
        _ = try eval("(.remove FileManager \"\(tempFile)\")")
    }
    
    func testGlob() throws {
        // We know Package.swift is in root
        // Glob current dir
        let files = try eval("(.glob FileManager \"Package.swift\")")
        XCTAssertTrue(files.contains("Package.swift"))
        
        // Recursive glob finding Swift files in Sources
        // "Sources/**/*.swift" -> using LIKE might need careful pattern
        // NSPredicate LIKE "Sources/**/*.swift" might not work exactly as standard glob
        // But let's test what we implemented: "SELF LIKE pattern" against subpaths.
        // If file is "Sources/AppleLisp/AppleLisp.swift", and pattern is "Sources/*.swift", LIKE matches? No.
        // "Sources/*/*.swift" matches.
        // Or "Sources*AppleLisp.swift"
        
        let swiftFiles = try eval("(.glob FileManager \"*.swift\")")
        // Should find Package.swift
        XCTAssertTrue(swiftFiles.contains("Package.swift"))
        
        let subFiles = try eval("(.glob FileManager \"*/*.swift\")")
        // Might find Sources/AppleLisp/*.swift if depth 1
        // We implemented recursive enumeration so paths are relative to root.
        // "Sources/AppleLisp/AppleLisp.swift"
        // Pattern "*AppleLisp.swift" should match
        
        let specific = try eval("(.glob FileManager \"*AppleLisp.swift\")")
        XCTAssertTrue(specific.contains("Sources/AppleLisp/AppleLisp.swift") || specific.contains("AppleLisp.swift"))
    }
}