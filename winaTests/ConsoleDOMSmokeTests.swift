import XCTest
@testable import wina

final class ConsoleDOMSmokeTests: XCTestCase {

    func testConsoleHookSerializesDOM() {
        let script = WebViewScripts.consoleHook

        XCTAssertTrue(script.contains("type: 'dom'"), "Console hook should serialize DOM values")
        XCTAssertTrue(script.contains("tag:"), "Console hook should include DOM tag")
        XCTAssertTrue(script.contains("attributes:"), "Console hook should include DOM attributes")
    }
}
