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

            // Helper to send message (no retry logic)
            function sendMessage(payload) {
                try {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
                        window.webkit.messageHandlers.consoleLog.postMessage(payload);
                    }
                } catch(e) {
                    // Silent fail
                }
            }

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

            // Parse CSS string to extract color, background, bold, fontSize
            function parseCSS(cssStr) {
                const result = { color: null, backgroundColor: null, isBold: false, fontSize: null };
                if (typeof cssStr !== 'string') return result;

                const props = cssStr.split(';');
                for (let i = 0; i < props.length; i++) {
                    const prop = props[i].trim();
                    if (!prop) continue;

                    const colonIdx = prop.indexOf(':');
                    if (colonIdx === -1) continue;

                    const key = prop.substring(0, colonIdx).trim();
                    const value = prop.substring(colonIdx + 1).trim();

                    if (key === 'color') {
                        result.color = value;
                    } else if (key === 'background' || key === 'background-color') {
                        result.backgroundColor = value;
                    } else if (key === 'font-weight' && (value === 'bold' || value === '700' || parseInt(value) >= 700)) {
                        result.isBold = true;
                    } else if (key === 'font-size') {
                        result.fontSize = parseInt(value);
                    }
                }
                return result;
            }

            // Format console message with %c, %s, %d, %i, %f, %o specifiers
            function formatConsoleMessage(args) {
                if (args.length === 0) return { message: '', objectJSON: null, styledSegments: null };

                const first = args[0];
                if (typeof first !== 'string') {
                    return { message: args.map(formatArg).join(' '), objectJSON: null, styledSegments: null };
                }

                if (!/%[sdifoOc%]/.test(first)) {
                    return { message: args.map(formatArg).join(' '), objectJSON: null, styledSegments: null };
                }

                let argIndex = 1;
                let message = '';
                let styledSegments = [];
                let currentCSS = null;
                let textBuffer = '';

                // Match all format specifiers
                const regex = /%[sdifoOc%]/g;
                let lastIndex = 0;
                let match;

                while ((match = regex.exec(first)) !== null) {
                    // Add text before specifier
                    if (match.index > lastIndex) {
                        const textBefore = first.substring(lastIndex, match.index);
                        textBuffer += textBefore;
                    }

                    const specifier = match[0];

                    if (specifier === '%%') {
                        textBuffer += '%';
                    } else if (argIndex < args.length) {
                        const arg = args[argIndex];

                        switch (specifier) {
                            case '%s':
                                textBuffer += String(arg);
                                argIndex++;
                                break;
                            case '%d':
                            case '%i':
                                textBuffer += String(parseInt(arg, 10));
                                argIndex++;
                                break;
                            case '%f':
                                textBuffer += String(parseFloat(arg));
                                argIndex++;
                                break;
                            case '%o':
                            case '%O':
                                textBuffer += formatArg(arg);
                                argIndex++;
                                break;
                            case '%c':
                                // Save current text with CSS, start new segment
                                if (textBuffer) {
                                    styledSegments.push({
                                        text: textBuffer,
                                        color: currentCSS?.color || null,
                                        backgroundColor: currentCSS?.backgroundColor || null,
                                        isBold: currentCSS?.isBold || false,
                                        fontSize: currentCSS?.fontSize || null
                                    });
                                    textBuffer = '';
                                }
                                // Next arg is CSS string
                                if (argIndex < args.length) {
                                    currentCSS = parseCSS(String(args[argIndex]));
                                    argIndex++;
                                }
                                break;
                        }
                    } else {
                        textBuffer += specifier;
                    }

                    lastIndex = match.index + specifier.length;
                }

                // Add remaining text
                if (lastIndex < first.length) {
                    textBuffer += first.substring(lastIndex);
                }

                // Save final text segment
                if (textBuffer) {
                    styledSegments.push({
                        text: textBuffer,
                        color: currentCSS?.color || null,
                        backgroundColor: currentCSS?.backgroundColor || null,
                        isBold: currentCSS?.isBold || false,
                        fontSize: currentCSS?.fontSize || null
                    });
                }

                // Build plain message from all segments
                message = styledSegments.map(function(seg) { return seg.text; }).join('');

                // Add remaining args to message
                while (argIndex < args.length) {
                    message += ' ' + formatArg(args[argIndex]);
                    argIndex++;
                }

                return {
                    message: message,
                    objectJSON: null,
                    styledSegments: styledSegments.length > 0 ? styledSegments : null
                };
            }

            const methods = ['log', 'info', 'warn', 'error', 'debug'];
            methods.forEach(function(method) {
                const original = console[method];
                console[method] = function(...args) {
                    try {
                        const formatted = formatConsoleMessage(args);
                        const source = getCallerSource();
                        const payload = {
                            type: method,
                            message: formatted.message,
                            source: source
                        };
                        if (formatted.styledSegments !== null) {
                            payload.styledSegments = formatted.styledSegments;
                        }
                        sendMessage(payload);
                    } catch(e) {}
                    original.apply(console, args);
                };
            });

            // console.group
            const originalGroup = console.group;
            console.group = function(...args) {
                try {
                    const formatted = args.length > 0 ? formatConsoleMessage(args) : { message: 'group', styledSegments: null };
                    const payload = {
                        type: 'group',
                        message: formatted.message,
                        source: getCallerSource()
                    };
                    if (formatted.styledSegments !== null) {
                        payload.styledSegments = formatted.styledSegments;
                    }
                    sendMessage(payload);
                } catch(e) {}
                originalGroup.apply(console, args);
            };

            // console.groupCollapsed
            const originalGroupCollapsed = console.groupCollapsed;
            console.groupCollapsed = function(...args) {
                try {
                    const formatted = args.length > 0 ? formatConsoleMessage(args) : { message: 'group', styledSegments: null };
                    const payload = {
                        type: 'groupCollapsed',
                        message: formatted.message,
                        source: getCallerSource()
                    };
                    if (formatted.styledSegments !== null) {
                        payload.styledSegments = formatted.styledSegments;
                    }
                    sendMessage(payload);
                } catch(e) {}
                originalGroupCollapsed.apply(console, args);
            };

            // console.groupEnd
            const originalGroupEnd = console.groupEnd;
            console.groupEnd = function() {
                try {
                    sendMessage({
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
                    sendMessage({
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
                sendMessage({
                    type: 'error',
                    message: 'Uncaught: ' + e.message,
                    source: source
                });
            });

            // Capture unhandled promise rejections
            window.addEventListener('unhandledrejection', function(e) {
                sendMessage({
                    type: 'error',
                    message: 'Unhandled Promise: ' + String(e.reason),
                    source: null
                });
            });
        })();
        """
}
