# Wallnut Network Tab Design - Eruda-Inspired Implementation

**Date**: 2025-12-22
**Status**: Design Phase - Learning from Eruda, Implementing for Wallnut
**Goal**: Extract best practices from Eruda's Network UI and adapt for Wallnut's Swift/WKWebView architecture

---

## Part 1: Eruda's Network Tab Best Practices

### Layout & UX Patterns

**Current Eruda Structure:**
```
┌─────────────────────────────────┐
│ Request List (compact rows)      │
├─────────────────────────────────┤
│ • GET api.example.com  200  150ms│
│ • POST api.example.com 201  45ms │
│ • GET cdn.example.com  304  20ms │
└─────────────────────────────────┘
    ↓ (tap request)
┌─────────────────────────────────┐
│ Detail Panel (tabs)              │
├─────────────────────────────────┤
│ General | Request | Response|... │
├─────────────────────────────────┤
│ • URL, Method, Status code       │
│ • Timing breakdown (waterfall)   │
│ • Headers with key-value display │
│ • Response body with formatting  │
└─────────────────────────────────┘
```

**Key Strengths:**
- ✅ Compact list view (method badge, URL, status, duration, type)
- ✅ Tab-based organization in detail view
- ✅ Response body syntax highlighting (JSON/HTML)
- ✅ Timing breakdown with visual waterfall
- ✅ Copy/export functionality
- ✅ Filter tabs at top
- ✅ Search bar integration
- ✅ Real-time updates (requests appear as they happen)

### Eruda Response Formatting

**JSON Display:**
```javascript
// Input (raw)
{"users":[{"id":1,"name":"John","email":"john@example.com"}]}

// Displayed (formatted)
{
  "users": [
    {
      "id": 1,
      "name": "John",
      "email": "john@example.com"
    }
  ]
}
// With syntax highlighting: keys (purple), strings (green), numbers (cyan), etc.
```

**HTML Display:**
```html
<!DOCTYPE html>
<html>
<head>
  <title>Example Page</title>
</head>
<body>
  <h1>Welcome</h1>
</body>
</html>
<!-- With syntax highlighting: tags (orange), attributes (blue), text (gray) -->
```

### Eruda Timing Breakdown

**Visual Representation:**
```
DNS Lookup     TCP Connect    SSL/TLS    Request Wait  Response Download
├──────────┤  ├──────────┤  ├───┤  ├──────────────┤  ├──────────────┤
    5ms          3ms         2ms         45ms              50ms
```

**Metadata:**
- DNS Lookup: Domain resolution time
- TCP Connect: Connection establishment
- SSL/TLS: Encryption handshake
- Request Wait: Time until first byte from server
- Response Download: Time to receive full response

**Calculation from Navigation Timing API:**
```javascript
timings = {
  dns: domainLookupEnd - domainLookupStart,
  tcp: connectEnd - connectStart,
  ssl: connectEnd - secureConnectionStart (if available),
  wait: responseStart - requestStart,
  download: responseEnd - responseStart
}
```

### Eruda Export Capability

**Supported Formats:**
- **Text**: Formatted list of requests
- **cURL**: Command to replay request
- **HAR**: HTTP Archive format (importable to Chrome)
- **Copy**: Copy as JSON

---

## Part 2: Wallnut Constraints & Adaptation Strategy

### WKWebView JavaScript Hook Limitations

**What we CAN capture:**
- Request/response headers (via fetch/XHR interception)
- Request/response body (full content)
- Status code and status text
- Request timing (via `performance.now()`)
- Content-Type detection
- Stack trace at request time

**What we CANNOT capture (WKWebView restriction):**
- ❌ DNS timing breakdown (not exposed to JavaScript)
- ❌ TCP connection time (platform API, not JS accessible)
- ❌ SSL/TLS handshake time (platform API)
- ❌ Redirect chain timing (WKWebView abstraction)
- ❌ Service Worker interception timing
- ❌ Network interface details

### Adapted Implementation Strategy

**Phase 1 - Core Features (implement now):**

1. **Response Body Formatting** ✅
   - JSON: Pretty-print + syntax highlighting
   - HTML: Display as-is with basic syntax highlighting
   - XML: Pretty-print with hierarchy
   - Images: Show as image preview (base64 or data URL)
   - Text: Display as-is with line numbers
   - Binary: Hex dump with ASCII representation

2. **Improved Timing Display** (⚠️ Limited by WKWebView)
   - Total duration (accurate)
   - Elapsed time breakdown:
     - Request prepare time (JavaScript overhead)
     - Server response time (from request start to first byte)
     - Download time (response size / time elapsed)
   - Visual bar chart (simplified waterfall)
   - ⚠️ Cannot show DNS/TCP/SSL breakdown without native iOS APIs

3. **Stack Trace Capture** ✅
   - Capture `Error().stack` at request initiation
   - Display filename, function name, line number
   - Help identify problematic request sources

**Phase 2 - Enhanced Filtering:**
- Status code filters (2xx, 3xx, 4xx, 5xx)
- Slow request detection (>1s, >5s)
- Content-Type filters (already have: JSON, HTML, etc.)
- Domain grouping

**Phase 3 - Export & Tools:**
- Export as JSON (full request/response)
- Export as HAR (for Chrome import)
- CSV export (for spreadsheet analysis)
- Request replay (modify and re-execute)

---

## Part 3: Detailed Implementation Plan - Phase 1

### 3.1 Response Body Formatting Component

**New File**: `Features/Network/ResponseFormatterView.swift`

```swift
struct ResponseFormatterView: View {
    let request: NetworkRequest
    let responseBody: String?
    let contentType: String

    var body: some View {
        ScrollView {
            switch contentType {
            case "JSON":
                JSONFormattedView(body: responseBody ?? "")
            case "HTML":
                HTMLFormattedView(body: responseBody ?? "")
            case "XML":
                XMLFormattedView(body: responseBody ?? "")
            case "Image":
                ImagePreviewView(body: responseBody ?? "")
            case "Text", "CSS", "JS":
                PlainTextView(body: responseBody ?? "", language: contentType)
            default:
                PlainTextView(body: responseBody ?? "", language: "Text")
            }
        }
    }
}

struct JSONFormattedView: View {
    let body: String

    var body: some View {
        // Parse JSON, format with indentation, apply syntax highlighting
        // Keys: purple, strings: green, numbers: cyan, booleans: yellow, null: gray
    }
}

struct HTMLFormattedView: View {
    let body: String

    var body: some View {
        // Display HTML with syntax highlighting
        // Tags: orange, attributes: blue, text: gray, comments: green
        // Could use Runestone for large files
    }
}
```

**Features:**
- Auto-detect content type from Content-Type header
- Pretty-print for JSON/XML
- Syntax highlighting with type-specific colors
- Copy button for formatted content
- Line numbers for code view
- Horizontal scroll for long lines

### 3.2 Timing Breakdown Display

**New File**: `Features/Network/NetworkTimingView.swift`

```swift
struct NetworkTimingView: View {
    let request: NetworkRequest

    var body: some View {
        VStack(spacing: 12) {
            // Timing summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(request.durationText)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.bottom, 8)

            Divider()

            // Timing breakdown (simplified)
            VStack(spacing: 8) {
                TimingBreakdownRow(
                    label: "Request → Response",
                    duration: request.duration,
                    color: .blue
                )
                // (Limited by WKWebView - cannot show DNS/TCP/SSL separately)
            }

            // Note about limitations
            Text("⚠️ WKWebView limitation: DNS, TCP, SSL breakdown not available from JavaScript")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }
}
```

**Features:**
- Total duration display
- Timing breakdown (limited by WKWebView)
- Visual bar representation
- Clear explanation of constraints
- Extensible for future native integration

### 3.3 Stack Trace Capture & Display

**Enhancement to NetworkManager:**

```swift
// In NetworkManager.swift - add to NetworkRequest
struct NetworkRequest {
    // ... existing fields

    // NEW: Stack trace information
    var initiatorStackTrace: [StackFrame]?
    var initiatorFunction: String?
    var initiatorFile: String?
    var initiatorLine: Int?
}

struct StackFrame: Identifiable, Equatable {
    let id = UUID()
    let functionName: String
    let fileName: String
    let lineNumber: Int
    let columnNumber: Int
}
```

**JavaScript Hook Enhancement:**

```javascript
// In existing JavaScript Hook, capture stack at request time
function captureStackTrace() {
    const stack = new Error().stack; // "Error\n at func1 (file1.js:10:5)\n ..."
    return parseStackTrace(stack);
}

function parseStackTrace(stack) {
    // Parse "at functionName (fileName:line:col)" format
    // Return array of {functionName, fileName, lineNumber, columnNumber}
}

// In fetch/XHR hook
const stack = captureStackTrace();
// Send to Swift with request
```

**Display Component:**

```swift
struct StackTraceView: View {
    let stackFrames: [StackFrame]?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Initiator Stack Trace")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if let frames = stackFrames, !frames.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(frames.prefix(5)) { frame in  // Show top 5 frames
                        HStack(spacing: 6) {
                            Text("▶")
                                .foregroundStyle(.secondary)
                                .frame(width: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(frame.functionName)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.primary)

                                Text("\(frame.fileName):\(frame.lineNumber):\(frame.columnNumber)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }

                    if (stackFrames?.count ?? 0) > 5 {
                        Text("... +\(stackFrames!.count - 5) more frames")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text("No stack trace available")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
```

**Features:**
- Shows top 5 stack frames
- Function name, file name, line number
- Helps identify problematic request sources
- Extensible for future click-to-navigate

### 3.4 Enhanced NetworkDetailView Layout

**Current Structure**: Headers and body in tabs

**Improved Structure:**

```
┌────────────────────────────┐
│ Request Details (tabs)      │
├────────────────────────────┤
│ Overview | Request | Resp..│
├────────────────────────────┤
│                            │
│ Overview Tab:             │
│  • URL, Method, Status     │
│  • Duration breakdown       │
│  • Stack trace             │
│  • Timing info             │
│                            │
│ Request Tab:              │
│  • Headers (key-value)     │
│  • Body (text/JSON/...)    │
│                            │
│ Response Tab:             │
│  • Headers (key-value)     │
│  • Body (formatted!)       │
│    - JSON with syntax      │
│    - HTML rendering        │
│    - Image preview         │
│    - Plain text            │
│                            │
└────────────────────────────┘
```

**Implementation**:
- Add `ResponseFormatterView` to Response tab
- Add `NetworkTimingView` to Overview tab
- Add `StackTraceView` to Overview tab
- Keep existing header display in Request/Response tabs

---

## Part 4: Implementation Order (Phase 1)

### Step 1: Enhance NetworkManager to capture stack traces
- **File**: `NetworkManager.swift`
- **Changes**:
  - Add stack trace fields to NetworkRequest
  - Parse JavaScript stack in message handler
  - Store parsed stack frames

### Step 2: Create ResponseFormatterView component
- **File**: `Features/Network/ResponseFormatterView.swift` (NEW)
- **Components**:
  - JSONFormattedView (pretty-print + syntax highlight)
  - HTMLFormattedView (syntax highlight)
  - PlainTextView (code view with syntax)
  - ImagePreviewView (image display)

### Step 3: Create NetworkTimingView component
- **File**: `Features/Network/NetworkTimingView.swift` (NEW)
- **Features**:
  - Total duration
  - Timing breakdown (within JavaScript limitations)
  - Visual representation

### Step 4: Create StackTraceView component
- **File**: `Features/Network/StackTraceView.swift` (NEW)
- **Features**:
  - Display top 5 stack frames
  - File name, function name, line number
  - Collapsible for more frames

### Step 5: Enhance NetworkDetailView
- **File**: `Features/Network/NetworkDetailView.swift`
- **Changes**:
  - Restructure tabs (Overview, Request, Response, ...)
  - Integrate new components into appropriate tabs
  - Add Copy buttons for formatted responses

### Step 6: Update JavaScript Hook for stack traces
- **File**: Inside WebViewNavigator or separate hook file
- **Changes**:
  - Capture Error().stack at fetch/XHR time
  - Parse stack frames
  - Include in request metadata

---

## Part 5: Design System Integration

### Colors (matching existing system)

```swift
// Response type colors (already defined in NetworkModels)
case "JSON": return .purple      // Keys
case "HTML": return .orange      // Tags
case "XML": return .teal         // Structure
case "Text": return .gray        // Plain
case "CSS": return .pink         // Styles
case "JS": return .yellow        // Scripts

// Syntax highlighting colors
let jsonKey = Color.purple       // "key"
let jsonString = Color.green     // "value"
let jsonNumber = Color.cyan      // 123
let jsonBoolean = Color.yellow   // true/false
let jsonNull = Color.gray        // null
```

### Typography

```swift
// Headers and labels
.font(.system(size: 12, weight: .semibold, design: .monospaced))

// Content
.font(.system(size: 11, design: .monospaced))

// Secondary info
.font(.system(size: 10, design: .monospaced))

// Captions
.font(.caption)
```

### Spacing

```swift
// Section spacing
VStack(spacing: 12) { ... }

// Item spacing
VStack(spacing: 6) { ... }

// Horizontal spacing in rows
HStack(spacing: 8) { ... }
```

---

## Part 6: Success Criteria

### Phase 1 Complete When:

- ✅ Stack trace captured in JavaScript Hook
- ✅ ResponseFormatterView renders JSON/HTML/XML/Images with syntax highlighting
- ✅ NetworkTimingView displays accurate timing within JavaScript limitations
- ✅ StackTraceView shows initiator call stack
- ✅ NetworkDetailView integrated with new components
- ✅ Design system colors and typography applied consistently
- ✅ All existing Network functionality still works
- ✅ No performance degradation with 100+ requests

### Testing Scenarios:

1. **JSON Response**: API endpoint returning JSON → formatted with syntax highlighting
2. **HTML Response**: Page HTML request → rendered with tag highlighting
3. **Image Response**: Image request → shown as preview
4. **Stack Trace**: Click request → see which JavaScript called it
5. **Timing**: Long request → see accurate duration
6. **Export**: Share network log → still works as before

---

## Part 7: Eruda vs Wallnut Positioning

### What Eruda Does Better:
- ✅ CORS header analysis (JavaScript context)
- ✅ Cache-Control inspection (direct header access)
- ✅ DNS/TCP/SSL timing (if available)
- ✅ Interactive in-page debugging

### What Wallnut Does Better:
- ✅ Response body formatting (proper UI rendering)
- ✅ Timing waterfall visualization (Swift charts)
- ✅ Stack trace integration (native callback)
- ✅ Export capabilities (HAR, JSON, CSV)
- ✅ iPad-optimized UI
- ✅ Request replay (native execution)

### Best Practice:
- **Quick Debugging**: Open Eruda (bottom-right overlay)
- **Deep Analysis**: Open Wallnut Network tab (full UI)
- **Performance Optimization**: Wallnut waterfall + metrics
- **API Issues**: Eruda CORS analysis + Wallnut replay

---

**Status**: Design document complete, ready for Phase 1 implementation
**Next**: Begin Step 1 (Enhance NetworkManager with stack trace capture)

