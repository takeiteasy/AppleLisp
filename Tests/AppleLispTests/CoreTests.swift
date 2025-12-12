import XCTest
@testable import AppleLisp

final class CoreTests: AppleLispTestCase {
    func testBasicArithmetic() throws {
        XCTAssertEqual(try eval("(+ 1 2)"), "3")
        XCTAssertEqual(try eval("(* 3 4)"), "12")
    }
    
    func testVariables() throws {
        _ = try eval("(def x 10)")
        XCTAssertEqual(try eval("x"), "10")
    }
    
    func testFunctions() throws {
        _ = try eval("(defn square [x] (* x x))")
        XCTAssertEqual(try eval("(square 5)"), "25")
    }
}
