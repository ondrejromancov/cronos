# macOS Menu Bar App Design Guidelines

Guidelines extracted from analyzing open-source macOS menu bar apps: Ice, Stats, Itsycal, Maccy, Reminders MenuBar, and SwiftBar.

---

## 1. Window & Panel Architecture

### Floating Panel Pattern
Use `NSPanel` for menu bar popups - not regular windows:

```swift
class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Key properties for menu bar behavior
        isFloatingPanel = true
        level = .floating

        // Native appearance
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isOpaque = false
        backgroundColor = .clear

        // Behavior
        hidesOnDeactivate = false
        animationBehavior = .none  // Snappy feel
    }
}
```

### Window Positioning
Position relative to status bar button with edge detection:

```swift
func positionRelativeToStatusItem(_ button: NSStatusBarButton) {
    guard let screen = NSScreen.main else { return }
    let frame = button.window?.frame ?? .zero

    var origin = NSPoint(
        x: frame.midX - contentRect.width / 2,
        y: frame.minY - contentRect.height - 2  // 2pt gap
    )

    // Prevent off-screen placement
    let maxX = screen.visibleFrame.maxX
    if origin.x + contentRect.width > maxX {
        origin.x = maxX - contentRect.width - 10
    }

    setFrameOrigin(origin)
}
```

---

## 2. Visual Effects & Backgrounds

### Native Blur Effect
Always use `NSVisualEffectView` for backgrounds:

```swift
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }
}
```

**Material choices:**
- `.popover` - Standard menu bar popup
- `.menu` - Dropdown menus
- `.sidebar` - Navigation sidebars
- `.windowBackground` - Settings windows

### SwiftUI Background Pattern
```swift
struct ContentView: View {
    var body: some View {
        ZStack {
            VisualEffectView(material: .popover)

            VStack {
                // Content here
            }
        }
    }
}
```

---

## 3. Color System

### Use System Colors
Never hardcode colors - use semantic system colors that adapt to light/dark mode:

```swift
// Text colors
NSColor.labelColor           // Primary text
NSColor.secondaryLabelColor  // Secondary text
NSColor.tertiaryLabelColor   // Disabled/placeholder
NSColor.controlTextColor     // Menu bar items

// Background colors
NSColor.controlBackgroundColor
NSColor.windowBackgroundColor

// Interactive states
NSColor.selectedContentBackgroundColor
NSColor.unemphasizedSelectedContentBackgroundColor
```

### Centralized Theme System (Itsycal pattern)
```swift
class Themer {
    static let shared = Themer()

    var textColor: NSColor { NSColor.labelColor }
    var secondaryTextColor: NSColor { NSColor.secondaryLabelColor }
    var hoveredCellColor: NSColor { NSColor.controlAccentColor.withAlphaComponent(0.1) }
    var selectedCellColor: NSColor { NSColor.controlAccentColor.withAlphaComponent(0.2) }
    var todayCellColor: NSColor { NSColor(named: "TodayCellColor")! }
}
```

### Usage-Based Color Progression (Stats pattern)
```swift
extension Double {
    func usageColor(zones: [Double] = [30, 60, 90]) -> NSColor {
        switch self {
        case 0..<zones[0]:    return .systemBlue
        case zones[0]..<zones[1]: return .systemGreen
        case zones[1]..<zones[2]: return .systemOrange
        default:              return .systemRed
        }
    }
}
```

---

## 4. Typography

### Menu Bar Font
```swift
// Standard menu bar font
let font = NSFont.menuBarFont(ofSize: 0)  // 0 = system default

// With specific size
let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
```

### Responsive Font Sizing (Itsycal pattern)
```swift
enum SizePreference: Int {
    case small = 0, medium = 1, large = 2

    var fontSize: CGFloat {
        switch self {
        case .small:  return 11
        case .medium: return 13
        case .large:  return 15
        }
    }

    var cellSize: CGFloat {
        switch self {
        case .small:  return 23
        case .medium: return 27
        case .large:  return 32
        }
    }
}
```

---

## 5. Layout Constants

### Standard Dimensions
```swift
struct LayoutConstants {
    // Popup dimensions
    static let popupWidth: CGFloat = 340
    static let popupMaxHeight: CGFloat = 460

    // Margins & spacing
    static let horizontalMargin: CGFloat = 8
    static let verticalMargin: CGFloat = 8
    static let itemSpacing: CGFloat = 4

    // Corner radius
    static let panelCornerRadius: CGFloat = 10
    static let buttonCornerRadius: CGFloat = 6
    static let cellCornerRadius: CGFloat = 4

    // Item heights
    static let menuBarHeight: CGFloat = 22
    static let listItemHeight: CGFloat = 28
    static let settingsRowHeight: CGFloat = 32
}
```

### Widget Dimensions (Stats pattern)
```swift
struct WidgetConstants {
    static let width: CGFloat = 32
    static let spacing: CGFloat = 2
    static let iconSize: CGFloat = 16
}
```

---

## 6. Interaction States

### Hover Effects
Use subtle opacity changes (0.08-0.1 alpha):

```swift
struct HoverableButton: View {
    @State private var isHovered = false

    var body: some View {
        Button(action: {}) {
            Image(systemName: "gear")
        }
        .buttonStyle(.plain)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
        )
        .onHover { isHovered = $0 }
    }
}
```

### AppKit Hover Pattern (Itsycal)
```swift
class MoButton: NSButton {
    private let hoverBox = NSBox()

    override func updateTrackingAreas() {
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            hoverBox.animator().fillColor = NSColor.controlTextColor
            hoverBox.animator().alphaValue = 0.08
        }
    }
}
```

### Selection State (Maccy pattern)
```swift
.foregroundStyle(isSelected ? Color.white : .primary)
.background(isSelected ? Color.accentColor.opacity(0.8) : .clear)
```

---

## 7. Animation Timing

### Standard Durations
```swift
struct AnimationDurations {
    static let instant: TimeInterval = 0.1
    static let fast: TimeInterval = 0.15
    static let normal: TimeInterval = 0.2
    static let slow: TimeInterval = 0.3
}
```

### Panel Resize Animation
```swift
func animateResize(to height: CGFloat) {
    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animator().setFrame(newFrame, display: true)
    }
}
```

### Fade Animations (Ice pattern)
```swift
func fadeIn() {
    alphaValue = 0
    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.15
        animator().alphaValue = 1
    }
}
```

---

## 8. Keyboard Navigation

### Global Hotkey Setup
```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePopup = Self("togglePopup", default: .init(.space, modifiers: [.command, .shift]))
}

// Registration
KeyboardShortcuts.onKeyDown(for: .togglePopup) {
    AppDelegate.shared.togglePopover()
}
```

### List Navigation (Maccy pattern)
```swift
struct KeyboardNavigableList: View {
    @State var selectedIndex = 0

    var body: some View {
        List(items) { item in
            // ...
        }
        .onKeyPress(.downArrow) {
            selectedIndex = min(selectedIndex + 1, items.count - 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(selectedIndex - 1, 0)
            return .handled
        }
        .onKeyPress(.return) {
            selectItem(at: selectedIndex)
            return .handled
        }
    }
}
```

---

## 9. Menu Bar Icon Design

### Status Item Setup
```swift
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

func configureStatusItem() {
    statusItem.button?.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Clipboard")
    statusItem.button?.imagePosition = .imageLeading
    statusItem.button?.action = #selector(togglePopover)
}
```

### Dynamic Icon with Text (Itsycal pattern)
```swift
func iconImage(for text: String) -> NSImage {
    let font = NSFont.systemFont(ofSize: 11.5, weight: .bold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.controlTextColor
    ]

    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size)
    image.lockFocus()

    let textSize = text.size(withAttributes: attributes)
    let point = NSPoint(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2
    )
    text.draw(at: point, withAttributes: attributes)

    image.unlockFocus()
    image.isTemplate = true  // Adapts to menu bar appearance
    return image
}
```

### SF Symbols in Menu Bar
```swift
// Basic usage
statusItem.button?.image = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: nil)

// With configuration
let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
statusItem.button?.image = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config)
```

---

## 10. List & Table Styling

### SwiftUI List Pattern
```swift
struct HistoryList: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(items) { item in
                    ItemRow(item: item)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
```

### Item Row Pattern
```swift
struct ItemRow: View {
    let item: Item
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(nsImage: item.icon)
                .frame(width: 16, height: 16)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Action
            if isHovered {
                Button(action: {}) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.05) : .clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
```

---

## 11. Search Field Design

### Minimal Search (Maccy pattern)
```swift
struct SearchField: View {
    @Binding var query: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.6))

            TextField("Search", text: $query)
                .textFieldStyle(.plain)
                .focused($isFocused)

            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
```

---

## 12. Settings Window Design

### Split View Pattern (Stats)
```swift
struct SettingsView: View {
    @State private var selectedTab = "general"

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("General", systemImage: "gear")
                    .tag("general")
                Label("Appearance", systemImage: "paintbrush")
                    .tag("appearance")
                Label("Advanced", systemImage: "slider.horizontal.3")
                    .tag("advanced")
            }
            .listStyle(.sidebar)
            .frame(width: 180)
        } detail: {
            switch selectedTab {
            case "general": GeneralSettings()
            case "appearance": AppearanceSettings()
            case "advanced": AdvancedSettings()
            default: EmptyView()
            }
        }
        .frame(width: 600, height: 400)
    }
}
```

### Settings Row Pattern
```swift
struct SettingsRow<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            content
        }
        .padding(.vertical, 4)
    }
}

// Usage
SettingsRow("Show in menu bar") {
    Toggle("", isOn: $showInMenuBar)
        .toggleStyle(.switch)
}
```

---

## 13. Performance Patterns

### Throttling Updates
```swift
class Throttler {
    private var workItem: DispatchWorkItem?
    private var lastRun = Date.distantPast
    let delay: TimeInterval

    init(_ delay: TimeInterval = 0.1) {
        self.delay = delay
    }

    func throttle(_ action: @escaping () -> Void) {
        workItem?.cancel()

        let elapsed = Date().timeIntervalSince(lastRun)
        let remaining = max(0, delay - elapsed)

        workItem = DispatchWorkItem { [weak self] in
            action()
            self?.lastRun = Date()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: workItem!)
    }
}
```

### Lazy Loading
```swift
// Use LazyVStack for long lists
LazyVStack(spacing: 4) {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}

// Defer expensive operations
.onAppear {
    Task {
        await item.loadThumbnail()
    }
}
```

### Concurrent Drawing (Stats pattern)
```swift
class CustomView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        canDrawConcurrently = true
    }
}
```

---

## 14. App Lifecycle

### Menu Bar Only App
```swift
@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene - all UI handled by AppDelegate
        Settings { }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
    }
}
```

### Dynamic Activation Policy (SwiftBar pattern)
```swift
func updateActivationPolicy() {
    let hasVisibleWindows = NSApp.windows.contains { $0.isVisible && !($0 is NSStatusBarButton) }
    NSApp.setActivationPolicy(hasVisibleWindows ? .regular : .accessory)
}
```

---

## Summary: Key Principles

1. **Native First** - Use system colors, fonts, and controls
2. **Minimal UI** - Remove unnecessary chrome, embrace whitespace
3. **Subtle Interactions** - Hover at 0.08 alpha, fast animations (0.15s)
4. **Keyboard Accessible** - Full navigation without mouse
5. **Performance** - Lazy loading, throttled updates, concurrent drawing
6. **Responsive** - Support multiple size preferences
7. **Dark Mode** - Automatic via system colors and semantic assets
8. **Menu Bar Behavior** - Non-activating panels, proper positioning

---

*Compiled from: Ice, Stats, Itsycal, Maccy, Reminders MenuBar, SwiftBar*
