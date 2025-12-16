//
//  WebViewScripts+Network.swift
//  wina
//
//  Network hook script for WebView.
//

import Foundation

extension WebViewScripts {
    /// Network hooking script - intercepts fetch and XMLHttpRequest
    static let networkHook = """
        (function() {
            if (window.__networkHooked) return;
            window.__networkHooked = true;

            // Generate unique request ID
            function generateId() {
                return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                    var r = Math.random() * 16 | 0;
                    var v = c === 'x' ? r : (r & 0x3 | 0x8);
                    return v.toString(16);
                });
            }

            // Resolve relative URL to absolute URL
            function resolveURL(url) {
                try {
                    return new URL(url, document.baseURI).href;
                } catch(e) {
                    return url;
                }
            }

            // Safely stringify headers
            function headersToObject(headers) {
                if (!headers) return null;
                var obj = {};
                if (headers.forEach) {
                    headers.forEach(function(value, key) {
                        obj[key] = value;
                    });
                } else if (typeof headers === 'object') {
                    for (var key in headers) {
                        if (headers.hasOwnProperty(key)) {
                            obj[key] = headers[key];
                        }
                    }
                }
                return Object.keys(obj).length > 0 ? obj : null;
            }

            // Truncate body for large payloads
            function truncateBody(body, maxLen) {
                maxLen = maxLen || 10000;
                if (!body) return null;
                if (typeof body !== 'string') {
                    try { body = JSON.stringify(body); } catch(e) { body = String(body); }
                }
                if (body.length > maxLen) {
                    return body.substring(0, maxLen) + '... (truncated)';
                }
                return body;
            }

            // Hook fetch
            var originalFetch = window.fetch;
            window.fetch = function(input, init) {
                var requestId = generateId();
                var rawUrl = typeof input === 'string' ? input : (input.url || String(input));
                var url = resolveURL(rawUrl);
                var method = (init && init.method) || (input && input.method) || 'GET';
                var headers = (init && init.headers) || (input && input.headers) || null;
                var body = (init && init.body) || null;

                try {
                    window.webkit.messageHandlers.networkRequest.postMessage({
                        action: 'start',
                        id: requestId,
                        method: method,
                        url: url,
                        type: 'fetch',
                        headers: headersToObject(headers),
                        body: truncateBody(body)
                    });
                } catch(e) {}

                return originalFetch.apply(this, arguments)
                    .then(function(response) {
                        var responseHeaders = {};
                        response.headers.forEach(function(value, key) {
                            responseHeaders[key] = value;
                        });

                        // Clone response to read body
                        var cloned = response.clone();
                        cloned.text().then(function(text) {
                            try {
                                window.webkit.messageHandlers.networkRequest.postMessage({
                                    action: 'complete',
                                    id: requestId,
                                    status: response.status,
                                    statusText: response.statusText,
                                    headers: responseHeaders,
                                    body: truncateBody(text)
                                });
                            } catch(e) {}
                        }).catch(function() {
                            try {
                                window.webkit.messageHandlers.networkRequest.postMessage({
                                    action: 'complete',
                                    id: requestId,
                                    status: response.status,
                                    statusText: response.statusText,
                                    headers: responseHeaders,
                                    body: null
                                });
                            } catch(e) {}
                        });

                        return response;
                    })
                    .catch(function(error) {
                        try {
                            window.webkit.messageHandlers.networkRequest.postMessage({
                                action: 'error',
                                id: requestId,
                                error: error.message || String(error)
                            });
                        } catch(e) {}
                        throw error;
                    });
            };

            // Hook XMLHttpRequest
            var XHR = XMLHttpRequest;
            var originalOpen = XHR.prototype.open;
            var originalSend = XHR.prototype.send;
            var originalSetRequestHeader = XHR.prototype.setRequestHeader;

            XHR.prototype.open = function(method, url) {
                this.__networkRequestId = generateId();
                this.__networkMethod = method;
                this.__networkUrl = resolveURL(url);
                this.__networkHeaders = {};
                return originalOpen.apply(this, arguments);
            };

            XHR.prototype.setRequestHeader = function(name, value) {
                if (this.__networkHeaders) {
                    this.__networkHeaders[name] = value;
                }
                return originalSetRequestHeader.apply(this, arguments);
            };

            XHR.prototype.send = function(body) {
                var xhr = this;
                var requestId = xhr.__networkRequestId;

                try {
                    window.webkit.messageHandlers.networkRequest.postMessage({
                        action: 'start',
                        id: requestId,
                        method: xhr.__networkMethod || 'GET',
                        url: xhr.__networkUrl || '',
                        type: 'xhr',
                        headers: xhr.__networkHeaders,
                        body: truncateBody(body)
                    });
                } catch(e) {}

                xhr.addEventListener('load', function() {
                    var responseHeaders = {};
                    var headerString = xhr.getAllResponseHeaders();
                    if (headerString) {
                        headerString.split('\\r\\n').forEach(function(line) {
                            var parts = line.split(': ');
                            if (parts.length === 2) {
                                responseHeaders[parts[0]] = parts[1];
                            }
                        });
                    }

                    try {
                        window.webkit.messageHandlers.networkRequest.postMessage({
                            action: 'complete',
                            id: requestId,
                            status: xhr.status,
                            statusText: xhr.statusText,
                            headers: Object.keys(responseHeaders).length > 0 ? responseHeaders : null,
                            body: truncateBody(xhr.responseText)
                        });
                    } catch(e) {}
                });

                xhr.addEventListener('error', function() {
                    try {
                        window.webkit.messageHandlers.networkRequest.postMessage({
                            action: 'error',
                            id: requestId,
                            error: 'Network error'
                        });
                    } catch(e) {}
                });

                xhr.addEventListener('abort', function() {
                    try {
                        window.webkit.messageHandlers.networkRequest.postMessage({
                            action: 'error',
                            id: requestId,
                            error: 'Request aborted'
                        });
                    } catch(e) {}
                });

                xhr.addEventListener('timeout', function() {
                    try {
                        window.webkit.messageHandlers.networkRequest.postMessage({
                            action: 'error',
                            id: requestId,
                            error: 'Request timeout'
                        });
                    } catch(e) {}
                });

                return originalSend.apply(this, arguments);
            };
        })();
        """
}
