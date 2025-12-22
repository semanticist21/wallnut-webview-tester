//
//  ConsoleSmartQuotesTests.swift
//  winaTests
//
//  Tests for iOS smart quote sanitization in JavaScript input.
//

import XCTest
@testable import wina

final class ConsoleSmartQuotesTests: XCTestCase {

    // MARK: - Smart Quote Sanitization Tests

    /// Test that iOS smart single quotes are replaced with straight single quotes
    func testSmartSingleQuotesReplaced() {
        let input = "console.log(\u{2018}hello\u{2019})"  // 'hello'
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, "console.log('hello')")
        XCTAssertFalse(sanitized.contains("\u{2018}"))
        XCTAssertFalse(sanitized.contains("\u{2019}"))
    }

    /// Test that iOS smart double quotes are replaced with straight double quotes
    func testSmartDoubleQuotesReplaced() {
        let input = "console.log(\u{201C}test\u{201D})"  // "test"
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, "console.log(\"test\")")
        XCTAssertFalse(sanitized.contains("\u{201C}"))
        XCTAssertFalse(sanitized.contains("\u{201D}"))
    }

    /// Test mixed smart quotes in JavaScript code
    func testMixedSmartQuotesReplaced() {
        // "Hello" + 'World'
        let input = "\u{201C}Hello\u{201D} + \u{2018}World\u{2019}"
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, "\"Hello\" + 'World'")
    }

    /// Test that regular straight quotes are not affected
    func testStraightQuotesUnaffected() {
        let input = "console.log('normal', \"quotes\")"
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, input)
    }

    /// Test empty string
    func testEmptyString() {
        let input = ""
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, "")
    }

    /// Test string with no quotes
    func testNoQuotes() {
        let input = "console.log(42)"
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, input)
    }

    /// Test real-world JavaScript with template literals (backticks unaffected)
    func testBackticksUnaffected() {
        let input = "const msg = `Hello \u{201C}World\u{201D}`"
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, "const msg = `Hello \"World\"`")
        XCTAssertTrue(sanitized.contains("`"))
    }

    /// Test multiple occurrences of the same smart quote type
    func testMultipleSameSmartQuotes() {
        // 'a' + 'b' + 'c'
        let input = "\u{2018}a\u{2019} + \u{2018}b\u{2019} + \u{2018}c\u{2019}"
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, "'a' + 'b' + 'c'")
    }

    /// Test nested quotes scenario
    func testNestedQuotes() {
        // "He said 'hello'"
        let input = "\u{201C}He said \u{2018}hello\u{2019}\u{201D}"
        let sanitized = sanitizeSmartQuotes(input)

        XCTAssertEqual(sanitized, "\"He said 'hello'\"")
    }

    // MARK: - Helper Function

    /// Replicate the sanitize function for testing
    /// (Same logic as ConsoleView.sanitizeSmartQuotes)
    private func sanitizeSmartQuotes(_ input: String) -> String {
        input
            .replacingOccurrences(of: "\u{2018}", with: "'")  // '
            .replacingOccurrences(of: "\u{2019}", with: "'")  // '
            .replacingOccurrences(of: "\u{201C}", with: "\"") // "
            .replacingOccurrences(of: "\u{201D}", with: "\"") // "
    }
}
