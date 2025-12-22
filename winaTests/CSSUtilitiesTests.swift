//
//  CSSUtilitiesTests.swift
//  winaTests
//
//  Tests for CSSFormatter and CSS parsing utilities
//

import XCTest
@testable import wina

// MARK: - CSS Formatter Tests

final class CSSFormatterTests: XCTestCase {

    // MARK: - Parse Properties Tests

    func testParseSimpleProperty() {
        let css = "{ color: red; }"
        let properties = CSSFormatter.parseProperties(from: css)

        XCTAssertEqual(properties.count, 1)
        XCTAssertEqual(properties[0].property, "color")
        XCTAssertEqual(properties[0].value, "red")
    }

    func testParseMultipleProperties() {
        let css = "{ color: red; background: blue; font-size: 16px; }"
        let properties = CSSFormatter.parseProperties(from: css)

        XCTAssertEqual(properties.count, 3)
        XCTAssertEqual(properties[0].property, "color")
        XCTAssertEqual(properties[0].value, "red")
        XCTAssertEqual(properties[1].property, "background")
        XCTAssertEqual(properties[1].value, "blue")
        XCTAssertEqual(properties[2].property, "font-size")
        XCTAssertEqual(properties[2].value, "16px")
    }

    func testParsePropertyWithComplexValue() {
        let css = "{ font-family: 'Arial', sans-serif; }"
        let properties = CSSFormatter.parseProperties(from: css)

        XCTAssertEqual(properties.count, 1)
        XCTAssertEqual(properties[0].property, "font-family")
        XCTAssertEqual(properties[0].value, "'Arial', sans-serif")
    }

    func testParsePropertyWithURL() {
        let css = "{ background-image: url('image.png'); }"
        let properties = CSSFormatter.parseProperties(from: css)

        XCTAssertEqual(properties.count, 1)
        XCTAssertEqual(properties[0].property, "background-image")
        XCTAssertEqual(properties[0].value, "url('image.png')")
    }

    func testParseEmptyContent() {
        let css = "{}"
        let properties = CSSFormatter.parseProperties(from: css)

        XCTAssertEqual(properties.count, 0)
    }

    func testParseWithoutBraces() {
        let css = "color: red; background: blue;"
        let properties = CSSFormatter.parseProperties(from: css)

        XCTAssertEqual(properties.count, 2)
    }

    // MARK: - Parse Rule Tests

    func testParseRegularRule() {
        let css = ".class { color: red; font-size: 14px; }"
        let result = CSSFormatter.parseRule(from: css)

        if case .properties(let props) = result {
            XCTAssertEqual(props.count, 2)
        } else {
            XCTFail("Expected properties, got keyframes")
        }
    }

    func testParseKeyframesRule() {
        let css = """
        @keyframes fadeIn {
            0% { opacity: 0; }
            100% { opacity: 1; }
        }
        """
        let result = CSSFormatter.parseRule(from: css)

        if case .keyframes(let frames) = result {
            XCTAssertEqual(frames.count, 2)
            XCTAssertEqual(frames[0].selector, "0%")
            XCTAssertEqual(frames[0].properties.count, 1)
            XCTAssertEqual(frames[0].properties[0].property, "opacity")
            XCTAssertEqual(frames[0].properties[0].value, "0")
            XCTAssertEqual(frames[1].selector, "100%")
        } else {
            XCTFail("Expected keyframes, got properties")
        }
    }

    func testParseWebkitKeyframesRule() {
        let css = """
        @-webkit-keyframes slide {
            from { transform: translateX(0); }
            to { transform: translateX(100px); }
        }
        """
        let result = CSSFormatter.parseRule(from: css)

        if case .keyframes(let frames) = result {
            XCTAssertEqual(frames.count, 2)
            XCTAssertEqual(frames[0].selector, "from")
            XCTAssertEqual(frames[1].selector, "to")
        } else {
            XCTFail("Expected keyframes, got properties")
        }
    }

    // MARK: - Format Tests

    func testFormatCSS() {
        let css = "{ color: red; background: blue; }"
        let formatted = CSSFormatter.format(css)

        XCTAssertTrue(formatted.contains("  color: red;"))
        XCTAssertTrue(formatted.contains("  background: blue;"))
    }
}

// MARK: - CSS Property Category Tests

final class CSSPropertyCategoryTests: XCTestCase {

    // MARK: - Category Detection Tests

    func testLayoutCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "display"), "Layout")
        XCTAssertEqual(CSSPropertyCategory.category(for: "visibility"), "Layout")
        XCTAssertEqual(CSSPropertyCategory.category(for: "overflow"), "Layout")
        XCTAssertEqual(CSSPropertyCategory.category(for: "overflow-x"), "Layout")
        XCTAssertEqual(CSSPropertyCategory.category(for: "z-index"), "Layout")
        XCTAssertEqual(CSSPropertyCategory.category(for: "box-sizing"), "Layout")
    }

    func testFlexboxCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "flex"), "Flexbox")
        XCTAssertEqual(CSSPropertyCategory.category(for: "flex-direction"), "Flexbox")
        XCTAssertEqual(CSSPropertyCategory.category(for: "align-items"), "Flexbox")
        XCTAssertEqual(CSSPropertyCategory.category(for: "justify-content"), "Flexbox")
        XCTAssertEqual(CSSPropertyCategory.category(for: "gap"), "Flexbox")
        XCTAssertEqual(CSSPropertyCategory.category(for: "row-gap"), "Flexbox")
        XCTAssertEqual(CSSPropertyCategory.category(for: "column-gap"), "Flexbox")
    }

    func testGridCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "grid"), "Grid")
        XCTAssertEqual(CSSPropertyCategory.category(for: "grid-template-columns"), "Grid")
        XCTAssertEqual(CSSPropertyCategory.category(for: "grid-area"), "Grid")
    }

    func testBoxModelCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "margin"), "Box Model")
        XCTAssertEqual(CSSPropertyCategory.category(for: "margin-top"), "Box Model")
        XCTAssertEqual(CSSPropertyCategory.category(for: "padding"), "Box Model")
        XCTAssertEqual(CSSPropertyCategory.category(for: "width"), "Box Model")
        XCTAssertEqual(CSSPropertyCategory.category(for: "height"), "Box Model")
        XCTAssertEqual(CSSPropertyCategory.category(for: "min-width"), "Box Model")
        XCTAssertEqual(CSSPropertyCategory.category(for: "max-height"), "Box Model")
    }

    func testPositionCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "position"), "Position")
        XCTAssertEqual(CSSPropertyCategory.category(for: "top"), "Position")
        XCTAssertEqual(CSSPropertyCategory.category(for: "right"), "Position")
        XCTAssertEqual(CSSPropertyCategory.category(for: "bottom"), "Position")
        XCTAssertEqual(CSSPropertyCategory.category(for: "left"), "Position")
        XCTAssertEqual(CSSPropertyCategory.category(for: "inset"), "Position")
    }

    func testTypographyCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "font-family"), "Typography")
        XCTAssertEqual(CSSPropertyCategory.category(for: "font-size"), "Typography")
        XCTAssertEqual(CSSPropertyCategory.category(for: "text-align"), "Typography")
        XCTAssertEqual(CSSPropertyCategory.category(for: "letter-spacing"), "Typography")
        XCTAssertEqual(CSSPropertyCategory.category(for: "line-height"), "Typography")
        XCTAssertEqual(CSSPropertyCategory.category(for: "color"), "Typography")
    }

    func testBackgroundCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "background"), "Background")
        XCTAssertEqual(CSSPropertyCategory.category(for: "background-color"), "Background")
        XCTAssertEqual(CSSPropertyCategory.category(for: "background-image"), "Background")
    }

    func testBorderCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "border"), "Border")
        XCTAssertEqual(CSSPropertyCategory.category(for: "border-radius"), "Border")
        XCTAssertEqual(CSSPropertyCategory.category(for: "outline"), "Border")
    }

    func testEffectsCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "box-shadow"), "Effects")
        XCTAssertEqual(CSSPropertyCategory.category(for: "opacity"), "Effects")
        XCTAssertEqual(CSSPropertyCategory.category(for: "filter"), "Effects")
        XCTAssertEqual(CSSPropertyCategory.category(for: "backdrop-filter"), "Effects")
    }

    func testAnimationCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "animation"), "Animation")
        XCTAssertEqual(CSSPropertyCategory.category(for: "animation-name"), "Animation")
        XCTAssertEqual(CSSPropertyCategory.category(for: "transition"), "Animation")
    }

    func testTransformCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "transform"), "Transform")
        XCTAssertEqual(CSSPropertyCategory.category(for: "perspective"), "Transform")
        XCTAssertEqual(CSSPropertyCategory.category(for: "rotate"), "Transform")
        XCTAssertEqual(CSSPropertyCategory.category(for: "scale"), "Transform")
    }

    func testInteractionCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "cursor"), "Interaction")
        XCTAssertEqual(CSSPropertyCategory.category(for: "pointer-events"), "Interaction")
        XCTAssertEqual(CSSPropertyCategory.category(for: "user-select"), "Interaction")
    }

    func testScrollCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "scroll-behavior"), "Scroll")
        XCTAssertEqual(CSSPropertyCategory.category(for: "overscroll-behavior"), "Scroll")
    }

    func testOtherCategory() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "unknown-property"), "Other")
        XCTAssertEqual(CSSPropertyCategory.category(for: "custom-property"), "Other")
    }

    func testCaseInsensitive() {
        XCTAssertEqual(CSSPropertyCategory.category(for: "DISPLAY"), "Layout")
        XCTAssertEqual(CSSPropertyCategory.category(for: "Font-Size"), "Typography")
    }

    // MARK: - All Categories Test

    func testAllCategoriesCount() {
        XCTAssertEqual(CSSPropertyCategory.allCategories.count, 14)
    }

    func testAllCategoriesContainsExpected() {
        let expected = [
            "Layout", "Flexbox", "Grid", "Box Model", "Position",
            "Typography", "Background", "Border", "Effects",
            "Animation", "Transform", "Interaction", "Scroll", "Other"
        ]

        for category in expected {
            XCTAssertTrue(CSSPropertyCategory.allCategories.contains(category), "Missing category: \(category)")
        }
    }
}
