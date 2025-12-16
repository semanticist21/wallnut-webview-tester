//
//  CSSPropertyCategory.swift
//  wina
//
//  CSS property categories for grouping computed styles (Chrome DevTools style).
//

import Foundation

/// CSS property categories for grouping computed styles (Chrome DevTools style)
enum CSSPropertyCategory {
    /// All categories in display order
    static let allCategories = [
        "Layout",
        "Flexbox",
        "Grid",
        "Box Model",
        "Position",
        "Typography",
        "Background",
        "Border",
        "Effects",
        "Animation",
        "Transform",
        "Interaction",
        "Scroll",
        "Other"
    ]

    /// Determine category for a CSS property
    static func category(for property: String) -> String {
        let prop = property.lowercased()

        // Layout
        if prop.hasPrefix("display") || prop.hasPrefix("visibility") ||
           prop.hasPrefix("overflow") || prop.hasPrefix("float") ||
           prop.hasPrefix("clear") || prop.hasPrefix("z-index") ||
           prop.hasPrefix("box-sizing") || prop.hasPrefix("contain") ||
           prop.hasPrefix("appearance") {
            return "Layout"
        }

        // Flexbox
        if prop.hasPrefix("flex") || prop.hasPrefix("align-") ||
           prop.hasPrefix("justify-") || prop.hasPrefix("order") ||
           prop.hasPrefix("gap") || prop == "row-gap" || prop == "column-gap" {
            return "Flexbox"
        }

        // Grid
        if prop.hasPrefix("grid") {
            return "Grid"
        }

        // Box Model
        if prop.hasPrefix("margin") || prop.hasPrefix("padding") ||
           prop.hasPrefix("width") || prop.hasPrefix("height") ||
           prop.hasPrefix("min-") || prop.hasPrefix("max-") ||
           prop == "aspect-ratio" || prop == "block-size" || prop == "inline-size" {
            return "Box Model"
        }

        // Position
        if prop.hasPrefix("position") || prop == "top" || prop == "right" ||
           prop == "bottom" || prop == "left" || prop.hasPrefix("inset") {
            return "Position"
        }

        // Typography
        if prop.hasPrefix("font") || prop.hasPrefix("text") ||
           prop.hasPrefix("letter") || prop.hasPrefix("word") ||
           prop.hasPrefix("line-") || prop.hasPrefix("white-space") ||
           prop == "color" || prop.hasPrefix("writing-mode") ||
           prop.hasPrefix("vertical-align") || prop.hasPrefix("direction") ||
           prop.hasPrefix("accent-color") {
            return "Typography"
        }

        // Background
        if prop.hasPrefix("background") {
            return "Background"
        }

        // Border
        if prop.hasPrefix("border") || prop.hasPrefix("outline") {
            return "Border"
        }

        // Effects
        if prop.hasPrefix("box-shadow") || prop.hasPrefix("opacity") ||
           prop.hasPrefix("filter") || prop.hasPrefix("backdrop") ||
           prop.hasPrefix("mix-blend") || prop.hasPrefix("isolation") ||
           prop.hasPrefix("mask") || prop.hasPrefix("clip") {
            return "Effects"
        }

        // Animation
        if prop.hasPrefix("animation") || prop.hasPrefix("transition") {
            return "Animation"
        }

        // Transform
        if prop.hasPrefix("transform") || prop.hasPrefix("perspective") ||
           prop.hasPrefix("rotate") || prop.hasPrefix("scale") ||
           prop.hasPrefix("translate") {
            return "Transform"
        }

        // Interaction
        if prop.hasPrefix("cursor") || prop.hasPrefix("pointer-events") ||
           prop.hasPrefix("user-select") || prop.hasPrefix("touch-action") ||
           prop.hasPrefix("resize") || prop.hasPrefix("caret") {
            return "Interaction"
        }

        // Scroll
        if prop.hasPrefix("scroll") || prop.hasPrefix("overscroll") ||
           prop.hasPrefix("snap") {
            return "Scroll"
        }

        return "Other"
    }
}
