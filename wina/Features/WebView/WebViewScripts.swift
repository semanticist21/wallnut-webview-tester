//
//  WebViewScripts.swift
//  wina
//
//  JavaScript injection scripts for WebView hooking.
//  Scripts are organized in extensions by functionality.
//

import Foundation

// MARK: - WebView Injection Scripts

/// JavaScript scripts for WKWebView feature hooking
///
/// Scripts are organized into extensions:
/// - WebViewScripts+Console.swift: Console hook script
/// - WebViewScripts+Network.swift: Network (fetch/XHR) hook script
/// - WebViewScripts+Emulation.swift: Performance observer and media query emulation
enum WebViewScripts {}
