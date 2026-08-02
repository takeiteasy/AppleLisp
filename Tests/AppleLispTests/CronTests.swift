import XCTest
@testable import AppleLisp

final class CronTests: AppleLispTestCase {
    func testSchedule() throws {
        let id = try eval("(.schedule Cron \"*/5 * * * *\" (fn [] (prn \"tick\")))")
        XCTAssertNotEqual(id, "nil")
        XCTAssertNotEqual(id, "undefined")
        XCTAssertFalse(id.isEmpty)
    }

    func testList() throws {
        _ = try eval("(.schedule Cron \"* * * * *\" (fn [] (prn \"tick\")))")
        let list = try eval("(.list Cron)")
        XCTAssertNotEqual(list, "nil")
        XCTAssertTrue(list.contains("expression"))
    }

    func testUnschedule() throws {
        let id = try eval("(.schedule Cron \"0 0 1 1 *\" (fn [] (prn \"tick\")))")
        _ = try eval("(.unschedule Cron \"\(id)\")")
        let list = try eval("(.list Cron)")
        XCTAssertFalse(list.contains(id))
    }

    func testInvalidExpression() throws {
        let id = try eval("(.schedule Cron \"not a cron\" (fn [] (prn \"tick\")))")
        XCTAssertEqual(id, "nil")
    }
}
