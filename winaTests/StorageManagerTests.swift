//
//  StorageManagerTests.swift
//  winaTests
//
//  Tests for StorageManager refresh and cookie domain filtering.
//

import Foundation
import XCTest
@testable import wina

final class StorageManagerTests: XCTestCase {

    @MainActor
    func testRefreshFiltersCookiesByDomain() async {
        let manager = StorageManager()
        let mock = MockStorageNavigator()
        mock.jsResult = "[]"
        mock.cookies = [
            makeCookie(name: "a", value: "1", domain: ".example.com"),
            makeCookie(name: "b", value: "2", domain: "sub.example.com"),
            makeCookie(name: "c", value: "3", domain: "other.com")
        ]

        manager.setNavigator(mock)
        await manager.refresh(
            includeAllCookies: false,
            pageURL: URL(string: "https://sub.example.com/path")
        )

        let cookieKeys = manager.items
            .filter { $0.storageType == .cookies }
            .map(\.key)
            .sorted()

        XCTAssertEqual(cookieKeys, ["a", "b"])
    }

    @MainActor
    func testRefreshIncludesAllCookiesWhenEnabled() async {
        let manager = StorageManager()
        let mock = MockStorageNavigator()
        mock.jsResult = "[]"
        mock.cookies = [
            makeCookie(name: "a", value: "1", domain: ".example.com"),
            makeCookie(name: "b", value: "2", domain: "sub.example.com"),
            makeCookie(name: "c", value: "3", domain: "other.com")
        ]

        manager.setNavigator(mock)
        await manager.refresh(
            includeAllCookies: true,
            pageURL: URL(string: "https://sub.example.com/path")
        )

        let cookieKeys = manager.items
            .filter { $0.storageType == .cookies }
            .map(\.key)
            .sorted()

        XCTAssertEqual(cookieKeys, ["a", "b", "c"])
    }
}

private final class MockStorageNavigator: StorageNavigator {
    var jsResult: Any?
    var cookies: [HTTPCookie] = []
    private(set) var scripts: [String] = []

    func evaluateJavaScript(_ script: String) async -> Any? {
        scripts.append(script)
        return jsResult
    }

    func getAllCookies() async -> [HTTPCookie] {
        cookies
    }

    func deleteCookie(name: String) async {
    }

    func deleteAllCookies() async {
    }
}

private func makeCookie(name: String, value: String, domain: String) -> HTTPCookie {
    let properties: [HTTPCookiePropertyKey: Any] = [
        .domain: domain,
        .path: "/",
        .name: name,
        .value: value
    ]
    return HTTPCookie(properties: properties)!
}
