//
//  WebViewScripts+Console.swift
//  wina
//
//  Console hook script for WebView.
//

import Foundation

extension WebViewScripts {
    /// Console hook script - intercepts console methods and forwards to native
    static let consoleHook = """
        (function() {
            if (window.__consoleHooked) return;
            window.__consoleHooked = true;

            // Parse stack trace to get caller location
            function getCallerSource() {
                try {
                    const stack = new Error().stack;
                    if (!stack) return null;
                    const lines = stack.split('\\n');
                    // Skip: Error, our hook function, console.method wrapper
                    // Find the first line that's not our code
                    for (let i = 3; i < lines.length; i++) {
                        const line = lines[i];
                        if (!line) continue;
                        // Match patterns like "at func (url:line:col)" or "url:line:col"
                        const match = line.match(/(?:at\\s+)?(?:[^(]+\\s+\\()?([^)\\s]+):(\\d+)(?::\\d+)?\\)?/);
                        if (match) {
                            let url = match[1];
                            const lineNum = match[2];
                            // Simplify URL: extract filename or hostname+path
                            try {
                                const parsed = new URL(url);
                                const path = parsed.pathname;
                                url = path.split('/').pop() || parsed.hostname + path;
                            } catch(e) {
                                // Use as-is if not a valid URL
                                url = url.split('/').pop() || url;
                            }
                            return url + ':' + lineNum;
                        }
                    }
                } catch(e) {}
                return null;
            }

            // Helper to format arguments
            function formatArg(arg) {
                if (arg === null) return 'null';
                if (arg === undefined) return 'undefined';
                if (typeof arg === 'function') return '[Function: ' + (arg.name || 'anonymous') + ']';
                if (typeof arg === 'symbol') return arg.toString();
                if (typeof arg === 'bigint') return arg.toString() + 'n';
                if (arg instanceof Error) return arg.name + ': ' + arg.message + (arg.stack ? '\\n' + arg.stack : '');
                if (arg instanceof Element) return '<' + arg.tagName.toLowerCase() + (arg.id ? '#' + arg.id : '') + (arg.className ? '.' + arg.className.split(' ').join('.') : '') + '>';
                if (arg instanceof RegExp) return arg.toString();
                if (arg instanceof Date) return 'Date(' + arg.toISOString() + ')';
                if (arg instanceof Promise) return 'Promise {<pending>}';
                if (arg instanceof Map) return 'Map(' + arg.size + ') {' + Array.from(arg.entries()).map(function(e) { return e[0] + ' => ' + e[1]; }).join(', ') + '}';
                if (arg instanceof Set) return 'Set(' + arg.size + ') {' + Array.from(arg).join(', ') + '}';
                if (ArrayBuffer.isView(arg)) return arg.constructor.name + '(' + arg.length + ') [' + Array.from(arg.slice(0, 10)).join(', ') + (arg.length > 10 ? ', ...' : '') + ']';
                if (arg instanceof ArrayBuffer) return 'ArrayBuffer(' + arg.byteLength + ')';
                if (typeof arg === 'object') {
                    try {
                        const str = JSON.stringify(arg, null, 2);
                        return str === '{}' && Object.keys(arg).length === 0 ? '{}' : (str === '{}' ? '[object ' + (arg.constructor?.name || 'Object') + ']' : str);
                    }
                    catch(e) { return '[object ' + (arg.constructor?.name || 'Object') + ']'; }
                }
                return String(arg);
            }

            const methods = ['log', 'info', 'warn', 'error', 'debug'];
            methods.forEach(function(method) {
                const original = console[method];
                console[method] = function(...args) {
                    try {
                        const message = args.map(formatArg).join(' ');
                        const source = getCallerSource();
                        window.webkit.messageHandlers.consoleLog.postMessage({
                            type: method,
                            message: message,
                            source: source
                        });
                    } catch(e) {}
                    original.apply(console, args);
                };
            });

            // console.group
            const originalGroup = console.group;
            console.group = function(...args) {
                try {
                    const message = args.length > 0 ? args.map(formatArg).join(' ') : 'group';
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        type: 'group',
                        message: message,
                        source: getCallerSource()
                    });
                } catch(e) {}
                originalGroup.apply(console, args);
            };

            // console.groupCollapsed
            const originalGroupCollapsed = console.groupCollapsed;
            console.groupCollapsed = function(...args) {
                try {
                    const message = args.length > 0 ? args.map(formatArg).join(' ') : 'group';
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        type: 'groupCollapsed',
                        message: message,
                        source: getCallerSource()
                    });
                } catch(e) {}
                originalGroupCollapsed.apply(console, args);
            };

            // console.groupEnd
            const originalGroupEnd = console.groupEnd;
            console.groupEnd = function() {
                try {
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        type: 'groupEnd',
                        message: '',
                        source: null
                    });
                } catch(e) {}
                originalGroupEnd.apply(console);
            };

            // console.table
            const originalTable = console.table;
            console.table = function(data, columns) {
                try {
                    let tableData = [];
                    if (Array.isArray(data)) {
                        tableData = data.map(function(item, index) {
                            if (typeof item === 'object' && item !== null) {
                                const row = { '(index)': String(index) };
                                const keys = columns || Object.keys(item);
                                keys.forEach(function(key) {
                                    row[key] = formatArg(item[key]);
                                });
                                return row;
                            }
                            return { '(index)': String(index), 'Value': formatArg(item) };
                        });
                    } else if (typeof data === 'object' && data !== null) {
                        Object.keys(data).forEach(function(key) {
                            const item = data[key];
                            if (typeof item === 'object' && item !== null) {
                                const row = { '(index)': key };
                                const keys = columns || Object.keys(item);
                                keys.forEach(function(k) {
                                    row[k] = formatArg(item[k]);
                                });
                                tableData.push(row);
                            } else {
                                tableData.push({ '(index)': key, 'Value': formatArg(item) });
                            }
                        });
                    }
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        type: 'table',
                        message: JSON.stringify(tableData),
                        source: getCallerSource()
                    });
                } catch(e) {}
                originalTable.apply(console, arguments);
            };

            // Capture uncaught errors
            window.addEventListener('error', function(e) {
                let source = null;
                if (e.filename) {
                    try {
                        const parsed = new URL(e.filename);
                        const path = parsed.pathname;
                        source = (path.split('/').pop() || parsed.hostname + path) + ':' + e.lineno;
                    } catch(err) {
                        source = e.filename + ':' + e.lineno;
                    }
                }
                window.webkit.messageHandlers.consoleLog.postMessage({
                    type: 'error',
                    message: 'Uncaught: ' + e.message,
                    source: source
                });
            });

            // Capture unhandled promise rejections
            window.addEventListener('unhandledrejection', function(e) {
                window.webkit.messageHandlers.consoleLog.postMessage({
                    type: 'error',
                    message: 'Unhandled Promise: ' + String(e.reason),
                    source: null
                });
            });
        })();
        """
}
