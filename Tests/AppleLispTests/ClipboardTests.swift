import XCTest
@testable import AppleLisp

final class ClipboardTests: AppleLispTestCase {
    func testClipboard() throws {
        let testStr = "AppleLispTestString-\(UUID().uuidString)"
        _ = try eval("(.setString Clipboard \"\(testStr)\")")
        XCTAssertEqual(try eval("(.getString Clipboard)"), testStr)
        
        _ = try eval("(.clear Clipboard)")
        let res = try eval("(.getString Clipboard)")
        // Depends on what clearing does vs getString behavior. 
        // If cleared, there is no string for type .string, so returns nil -> undefined.
        XCTAssertTrue(res == "undefined" || res == "nil")
    }

    func testNamedClipboard() throws {
        let testStr = "NamedBoardTest-\(UUID().uuidString)"
        let boardName = "com.applelisp.testboard"
        
        _ = try eval("(.setString Clipboard \"\(testStr)\" nil \"\(boardName)\")")
        XCTAssertEqual(try eval("(.getString Clipboard nil \"\(boardName)\")"), testStr)
        
        _ = try eval("(.clear Clipboard \"\(boardName)\")")
        let res = try eval("(.getString Clipboard nil \"\(boardName)\")")
        XCTAssertTrue(res == "undefined" || res == "nil")
    }
    
    func testDataTypes() throws {
        let html = "<b>Bold</b>"
        let type = "public.html"
        
        _ = try eval("(.setString Clipboard \"\(html)\" \"\(type)\")")
        XCTAssertEqual(try eval("(.getString Clipboard \"\(type)\")"), html)
        
        // Check types
        let typesStr = try eval("(.getTypes Clipboard)")
        XCTAssertTrue(typesStr.contains(type))
    }
    
    func testBinaryData() throws {
        let original = "Hello World"
        let base64 = Data(original.utf8).base64EncodedString()
        let type = "public.plain-text" 
        
        _ = try eval("(.setData Clipboard \"\(base64)\" \"\(type)\")")
        XCTAssertEqual(try eval("(.getData Clipboard \"\(type)\")"), base64)
        XCTAssertEqual(try eval("(.getString Clipboard \"\(type)\")"), original)
    }
}