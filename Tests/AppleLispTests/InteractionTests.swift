import XCTest
@testable import AppleLisp

final class InteractionTests: AppleLispTestCase {
    // Note: Interaction tests are hard to fully automate as they involve UI.
    // These tests primarily ensure the API functions can be called without crashing
    // and that basic return values are as expected for non-UI interaction.
    
    // func testAlert() throws {
    //     // Test a simple alert. This will display a modal alert.
    //     // In an automated test environment without UI interaction, this will block.
    //     // For testing purposes, we simply ensure the API call can be made.
    //     // It's assumed a human user would dismiss this during development or manual testing.
    //     _ = try eval("(.alert Interaction \"Test Message\")")
    //     
    //     // Test alert with custom buttons. Same blocking considerations apply.
    //     _ = try eval("(.alert Interaction \"Confirm?\" (obj \"buttons\" [\"Yes\" \"No\"]))")
    // }
    // 
    // func testPrompt() throws {
    //     // Test a simple prompt. This will display a modal prompt.
    //     // Similar to alerts, this will block and requires user input.
    //     // We ensure the API call can be made.
    //     _ = try eval("(.prompt Interaction \"Enter value\" \"DefaultValue\")")
    //     
    //     // Test secure prompt.
    //     _ = try eval("(.prompt Interaction \"Enter password\" nil (obj \"secure\" true))")
    // }
    
    // chooseFile and chooseFolder are also highly interactive and hard to automate.
    // We'll primarily test that they can be called.
    // func testChooseFile() throws {
    //     let result = try eval("(.chooseFile Interaction nil)")
    //     XCTAssertTrue(result == "nil" || result == "undefined") // Assumes user cancels or selects nothing.
    //     
    //     // Test with options, assumes cancellation.
    //     let resultWithOptions = try eval("(.chooseFile Interaction (obj \"message\" \"Select a file\" \"multiple\" true))")
    //     XCTAssertTrue(resultWithOptions == "nil" || resultWithOptions == "undefined" || resultWithOptions.isEmpty)
    // }
    // 
    // func testChooseFolder() throws {
    //     let result = try eval("(.chooseFolder Interaction nil)")
    //     XCTAssertTrue(result == "nil" || result == "undefined") // Assumes user cancels.
    // }
}
