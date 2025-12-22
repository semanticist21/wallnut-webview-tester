//
//  StackFrameTests.swift
//  winaTests
//
//  Tests for StackFrame model and display functionality.
//

import XCTest
@testable import wina

final class StackFrameTests: XCTestCase {

    // MARK: - Initialization

    func testStackFrameInitialization() {
        let frame = StackFrame(
            functionName: "fetchData",
            fileName: "api/data.js",
            lineNumber: 42,
            columnNumber: 15
        )

        XCTAssertEqual(frame.functionName, "fetchData")
        XCTAssertEqual(frame.fileName, "api/data.js")
        XCTAssertEqual(frame.lineNumber, 42)
        XCTAssertEqual(frame.columnNumber, 15)
        XCTAssertNotNil(frame.id)
    }

    func testStackFrameInitializationWithCustomId() {
        let customId = UUID()
        let frame = StackFrame(
            id: customId,
            functionName: "processRequest",
            fileName: "handlers.js",
            lineNumber: 100,
            columnNumber: 5
        )

        XCTAssertEqual(frame.id, customId)
        XCTAssertEqual(frame.functionName, "processRequest")
    }

    // MARK: - Display Text

    func testDisplayText() {
        let frame = StackFrame(
            functionName: "handleClick",
            fileName: "/app/src/pages/home.js",
            lineNumber: 25,
            columnNumber: 10
        )

        let expected = "handleClick (/app/src/pages/home.js:25:10)"
        XCTAssertEqual(frame.displayText, expected)
    }

    func testDisplayTextWithSimplePath() {
        let frame = StackFrame(
            functionName: "onSubmit",
            fileName: "form.js",
            lineNumber: 50,
            columnNumber: 3
        )

        let expected = "onSubmit (form.js:50:3)"
        XCTAssertEqual(frame.displayText, expected)
    }

    // MARK: - Display File Name

    func testDisplayFileNameWithPath() {
        let frame = StackFrame(
            functionName: "fetch",
            fileName: "/Users/dev/project/src/api/users.js",
            lineNumber: 1,
            columnNumber: 1
        )

        XCTAssertEqual(frame.displayFileName, "users.js")
    }

    func testDisplayFileNameWithoutPath() {
        let frame = StackFrame(
            functionName: "load",
            fileName: "config.js",
            lineNumber: 1,
            columnNumber: 1
        )

        XCTAssertEqual(frame.displayFileName, "config.js")
    }

    func testDisplayFileNameWithComplexPath() {
        let frame = StackFrame(
            functionName: "render",
            fileName: "/app/node_modules/@react/dom/index.js",
            lineNumber: 500,
            columnNumber: 20
        )

        XCTAssertEqual(frame.displayFileName, "index.js")
    }

    // MARK: - Equatable

    func testStackFrameEquality() {
        let id = UUID()
        let frame1 = StackFrame(
            id: id,
            functionName: "fetchData",
            fileName: "api.js",
            lineNumber: 10,
            columnNumber: 5
        )
        let frame2 = StackFrame(
            id: id,
            functionName: "fetchData",
            fileName: "api.js",
            lineNumber: 10,
            columnNumber: 5
        )

        XCTAssertEqual(frame1, frame2)
    }

    func testStackFrameInequality() {
        let frame1 = StackFrame(
            functionName: "fetchData",
            fileName: "api.js",
            lineNumber: 10,
            columnNumber: 5
        )
        let frame2 = StackFrame(
            functionName: "fetchData",
            fileName: "api.js",
            lineNumber: 10,
            columnNumber: 6  // Different column
        )

        XCTAssertNotEqual(frame1, frame2)
    }

    func testStackFrameInequalityDifferentFunctionName() {
        let id = UUID()
        let frame1 = StackFrame(
            id: id,
            functionName: "fetchData",
            fileName: "api.js",
            lineNumber: 10,
            columnNumber: 5
        )
        let frame2 = StackFrame(
            id: id,
            functionName: "loadData",
            fileName: "api.js",
            lineNumber: 10,
            columnNumber: 5
        )

        XCTAssertNotEqual(frame1, frame2)
    }

    // MARK: - Codable

    func testStackFrameCoding() throws {
        let frame = StackFrame(
            functionName: "myFunction",
            fileName: "test.js",
            lineNumber: 42,
            columnNumber: 10
        )

        let encoded = try JSONEncoder().encode(frame)
        let decoded = try JSONDecoder().decode(StackFrame.self, from: encoded)

        XCTAssertEqual(decoded.functionName, frame.functionName)
        XCTAssertEqual(decoded.fileName, frame.fileName)
        XCTAssertEqual(decoded.lineNumber, frame.lineNumber)
        XCTAssertEqual(decoded.columnNumber, frame.columnNumber)
        XCTAssertEqual(decoded.id, frame.id)
    }

    // MARK: - Array Operations

    func testStackFrameArrayInitialization() {
        let frames = [
            StackFrame(functionName: "func1", fileName: "file1.js", lineNumber: 1, columnNumber: 1),
            StackFrame(functionName: "func2", fileName: "file2.js", lineNumber: 2, columnNumber: 2),
            StackFrame(functionName: "func3", fileName: "file3.js", lineNumber: 3, columnNumber: 3)
        ]

        XCTAssertEqual(frames.count, 3)
        XCTAssertEqual(frames[0].functionName, "func1")
        XCTAssertEqual(frames[2].functionName, "func3")
    }

    func testStackFrameArrayPrefix() {
        let frames = [
            StackFrame(functionName: "func1", fileName: "file1.js", lineNumber: 1, columnNumber: 1),
            StackFrame(functionName: "func2", fileName: "file2.js", lineNumber: 2, columnNumber: 2),
            StackFrame(functionName: "func3", fileName: "file3.js", lineNumber: 3, columnNumber: 3),
            StackFrame(functionName: "func4", fileName: "file4.js", lineNumber: 4, columnNumber: 4),
            StackFrame(functionName: "func5", fileName: "file5.js", lineNumber: 5, columnNumber: 5)
        ]

        let first3 = Array(frames.prefix(3))
        XCTAssertEqual(first3.count, 3)
        XCTAssertEqual(first3.last?.functionName, "func3")
    }

    // MARK: - Identifiable

    func testStackFrameIdentifiable() {
        let frame = StackFrame(
            functionName: "test",
            fileName: "test.js",
            lineNumber: 1,
            columnNumber: 1
        )

        // Verify Identifiable protocol conformance
        let _: UUID = frame.id
        XCTAssertNotNil(frame.id)
    }
}
