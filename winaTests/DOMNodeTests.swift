//
//  DOMNodeTests.swift
//  winaTests
//
//  Tests for DOMNode path-based stable IDs.
//  Ensures expand/collapse state is preserved across re-parses.
//

import Testing
@testable import wina

// MARK: - DOMNode ID Stability Tests

@Suite("DOMNode ID Stability")
struct DOMNodeIdStabilityTests {

    // MARK: - Path-Based ID Generation

    @Test("ID is derived from path")
    func testIdDerivedFromPath() {
        let node = DOMNode(
            path: [0, 1, 2],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.id == "0.1.2")
    }

    @Test("Root node has simple ID")
    func testRootNodeId() {
        let root = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "HTML",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(root.id == "0")
    }

    @Test("Same path produces same ID")
    func testSamePathSameId() {
        let node1 = DOMNode(
            path: [0, 1, 3],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["id": "first"],
            textContent: nil,
            children: []
        )
        let node2 = DOMNode(
            path: [0, 1, 3],
            nodeType: 1,
            nodeName: "SPAN",
            attributes: ["id": "second"],
            textContent: nil,
            children: []
        )

        #expect(node1.id == node2.id, "Same path should produce same ID regardless of content")
    }

    @Test("Different paths produce different IDs")
    func testDifferentPathsDifferentIds() {
        let node1 = DOMNode(
            path: [0, 1],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )
        let node2 = DOMNode(
            path: [0, 2],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node1.id != node2.id)
    }

    // MARK: - ID Stability Across Re-Parses

    @Test("ID remains stable when DOM is re-parsed")
    func testIdStableAcrossReparses() {
        // Simulate first parse
        let firstParse = DOMNode(
            path: [0, 1, 2],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "container"],
            textContent: nil,
            children: []
        )

        // Simulate second parse (same structure, different instance)
        let secondParse = DOMNode(
            path: [0, 1, 2],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "container updated"],
            textContent: nil,
            children: []
        )

        #expect(firstParse.id == secondParse.id, "ID should remain stable across re-parses for SwiftUI state preservation")
    }
}

// MARK: - DOMNode Display Name Tests

@Suite("DOMNode Display Name")
struct DOMNodeDisplayNameTests {

    @Test("Element display name shows tag")
    func testElementDisplayName() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div")
    }

    @Test("Element with ID shows id")
    func testElementWithId() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["id": "main"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div#main")
    }

    @Test("Element with class shows classes")
    func testElementWithClass() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "container flex"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div.container.flex")
    }

    @Test("Element with ID and class shows both")
    func testElementWithIdAndClass() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["id": "main", "class": "container"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div#main.container")
    }

    @Test("Text node shows content")
    func testTextNodeDisplayName() {
        let node = DOMNode(
            path: [0, 1],
            nodeType: 3,
            nodeName: "#text",
            attributes: [:],
            textContent: "Hello World",
            children: []
        )

        #expect(node.displayName == "Hello World")
    }

    @Test("Only first two classes shown")
    func testClassLimit() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "one two three four"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div.one.two")
    }
}

// MARK: - DOMNode Type Checks

@Suite("DOMNode Type Checks")
struct DOMNodeTypeTests {

    @Test("Element node type is 1")
    func testElementNodeType() {
        let element = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(element.isElement == true)
        #expect(element.isText == false)
    }

    @Test("Text node type is 3")
    func testTextNodeType() {
        let text = DOMNode(
            path: [0, 1],
            nodeType: 3,
            nodeName: "#text",
            attributes: [:],
            textContent: "content",
            children: []
        )

        #expect(text.isElement == false)
        #expect(text.isText == true)
    }
}

// MARK: - DOMNode Hashable Tests

@Suite("DOMNode Hashable")
struct DOMNodeHashableTests {

    @Test("Same node instance hashes consistently")
    func testSameNodeHashesConsistently() {
        let node = DOMNode(
            path: [0, 1, 2],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        // Same instance should always produce same hash
        #expect(node.hashValue == node.hashValue)
    }

    @Test("Identical nodes hash equally")
    func testIdenticalNodesHashEqually() {
        let node1 = DOMNode(
            path: [0, 1, 2],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )
        let node2 = DOMNode(
            path: [0, 1, 2],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node1.hashValue == node2.hashValue)
    }

    @Test("Can be used in Set")
    func testSetUsage() {
        let node1 = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )
        let node2 = DOMNode(
            path: [0, 1],
            nodeType: 1,
            nodeName: "SPAN",
            attributes: [:],
            textContent: nil,
            children: []
        )

        var set = Set<DOMNode>()
        set.insert(node1)
        set.insert(node2)

        #expect(set.count == 2)
    }
}

// MARK: - DOMNode Path Boundary Tests

@Suite("DOMNode Path Boundaries")
struct DOMNodePathBoundaryTests {

    // MARK: - Empty Path

    @Test("Empty path produces empty ID")
    func testEmptyPath() {
        let node = DOMNode(
            path: [],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.id.isEmpty)
    }

    // MARK: - Large Index Values

    @Test("Path with Int.max index")
    func testPathWithIntMax() {
        let node = DOMNode(
            path: [0, Int.max],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.id == "0.\(Int.max)")
    }

    @Test("Path with zero index")
    func testPathWithZeroIndex() {
        let node = DOMNode(
            path: [0, 0, 0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.id == "0.0.0")
    }

    // MARK: - Deep Paths

    @Test("Very deep path (100 levels)")
    func testVeryDeepPath() {
        let deepPath = Array(0..<100)
        let node = DOMNode(
            path: deepPath,
            nodeType: 1,
            nodeName: "SPAN",
            attributes: [:],
            textContent: nil,
            children: []
        )

        let expectedId = deepPath.map(String.init).joined(separator: ".")
        #expect(node.id == expectedId)
        #expect(node.id.contains("99"))
    }

    @Test("Single element path boundary")
    func testSingleElementPath() {
        let node = DOMNode(
            path: [999],
            nodeType: 1,
            nodeName: "DIV",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.id == "999")
    }
}

// MARK: - DOMNode nodeType Boundary Tests

@Suite("DOMNode nodeType Boundaries")
struct DOMNodeTypeBoundaryTests {

    @Test("nodeType 0 is neither element nor text")
    func testNodeTypeZero() {
        let node = DOMNode(
            path: [0],
            nodeType: 0,
            nodeName: "UNKNOWN",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.isElement == false)
        #expect(node.isText == false)
    }

    @Test("nodeType 2 (attribute) is neither element nor text")
    func testNodeTypeAttribute() {
        let node = DOMNode(
            path: [0],
            nodeType: 2,
            nodeName: "ATTR",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.isElement == false)
        #expect(node.isText == false)
    }

    @Test("nodeType 8 (comment) is neither element nor text")
    func testNodeTypeComment() {
        let node = DOMNode(
            path: [0],
            nodeType: 8,
            nodeName: "#comment",
            attributes: [:],
            textContent: "This is a comment",
            children: []
        )

        #expect(node.isElement == false)
        #expect(node.isText == false)
    }

    @Test("nodeType 9 (document) is neither element nor text")
    func testNodeTypeDocument() {
        let node = DOMNode(
            path: [0],
            nodeType: 9,
            nodeName: "#document",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.isElement == false)
        #expect(node.isText == false)
    }

    @Test("Negative nodeType is neither element nor text")
    func testNegativeNodeType() {
        let node = DOMNode(
            path: [0],
            nodeType: -1,
            nodeName: "INVALID",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.isElement == false)
        #expect(node.isText == false)
    }
}

// MARK: - DOMNode displayName Boundary Tests

@Suite("DOMNode displayName Boundaries")
struct DOMNodeDisplayNameBoundaryTests {

    @Test("Empty nodeName for element")
    func testEmptyNodeName() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.displayName.isEmpty)
    }

    @Test("Text node with nil textContent")
    func testTextNodeNilContent() {
        let node = DOMNode(
            path: [0],
            nodeType: 3,
            nodeName: "#text",
            attributes: [:],
            textContent: nil,
            children: []
        )

        #expect(node.displayName.isEmpty)
    }

    @Test("Text node with empty textContent")
    func testTextNodeEmptyContent() {
        let node = DOMNode(
            path: [0],
            nodeType: 3,
            nodeName: "#text",
            attributes: [:],
            textContent: "",
            children: []
        )

        #expect(node.displayName.isEmpty)
    }

    @Test("Class with only whitespace")
    func testWhitespaceOnlyClass() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "   "],
            textContent: nil,
            children: []
        )

        // Whitespace splits to empty, prefix(2) gets empty strings
        #expect(node.displayName == "div.")
    }

    @Test("Empty class attribute")
    func testEmptyClassAttribute() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": ""],
            textContent: nil,
            children: []
        )

        // Empty class should not add dot
        #expect(node.displayName == "div")
    }

    @Test("Exactly 2 classes")
    func testExactlyTwoClasses() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "first second"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div.first.second")
    }

    @Test("Single class")
    func testSingleClass() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "only"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div.only")
    }

    @Test("ID with special characters")
    func testIdWithSpecialCharacters() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["id": "my-id_123"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div#my-id_123")
    }

    @Test("Empty ID attribute")
    func testEmptyIdAttribute() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["id": ""],
            textContent: nil,
            children: []
        )

        // Empty ID should still add #
        #expect(node.displayName == "div#")
    }

    @Test("Very long class name")
    func testVeryLongClassName() {
        let longClass = String(repeating: "a", count: 1000)
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": longClass],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div.\(longClass)")
    }

    @Test("Unicode in class name")
    func testUnicodeClassName() {
        let node = DOMNode(
            path: [0],
            nodeType: 1,
            nodeName: "DIV",
            attributes: ["class": "한글클래스 emoji🎉"],
            textContent: nil,
            children: []
        )

        #expect(node.displayName == "div.한글클래스.emoji🎉")
    }
}
