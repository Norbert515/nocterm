# 0.9.0

## Features
- **Box-line blending**: Dividers and borders now merge with box-drawing characters they overlap, forming junctions (`├ ┤ ┬ ┴ ┼`) instead of leaving gaps. Every line character is modeled as four arms (up/right/down/left) with light/heavy/double weights; drawing one on another combines the arms and emits the matching glyph. New `mergeBoxCharacters`/`mergeArmsIntoCharacter` utilities, `TerminalCanvas.drawText(blendBoxLines:)`, and `TerminalCanvas.drawJunction`
- **Divider**: A negative `indent`/`endIndent` reaches the divider outside its own bounds; those cells contribute only the arm pointing back into the rule, so an end landing on a border forms a tee (`├`), not a cross. An end with nothing to join paints nothing
- **BoxBorder**: An overlaid panel's border corners merge with box characters beneath them, so a docked panel tees into the border it lands on
- **BoxBorderStyle.bold**: New heavy border style (`┏ ━ ┓`)
- Demo: `example/box_line_blending_demo.dart` shows dividers, crossings, all weights, and an overlaid panel

## Behavior Changes
- **Blending is always on** for `Divider`, `VerticalDivider`, and border corners (the `ascii` divider style never merges). When both characters carry an arm in the same direction, the newly drawn character wins (z-order), so drawing `╭` over `┌` rounds the corner and vice versa
- **Dotted borders**: Edges now use light triple-dash (`┄ ┆`) instead of heavy (`┅ ┇`) to match their light corners

## Bug Fixes
- **Divider**: No longer throws (discarding the whole frame) when laid out under unbounded constraints
- **Divider**: A cell the merge leaves unchanged keeps its original style instead of being recolored
- **BoxBorder**: Vertical sides run the full height of the box when no top/bottom border paints the end cells, so backgrounds no longer show holes
- **BorderTitle**: A styled title keeps the panel background instead of showing what was underneath
- **LogServer**: Each server can publish its port to its own file (`portFilePath`), so multiple servers in one process no longer race on the pid-keyed global file
- **getProjectDirectory**: Accepts an explicit starting directory to avoid racing on process-wide `Directory.current`

---

# 0.8.0

## Bug Fixes
- **IME composition (Windows/CJK)**: Emit each rendered frame in a single pipe write so the terminal never anchors the IME composition window to a transient streaming cell — fixes IME window flickering across the screen during chat/log streaming
- **IME cursor**: Stabilize IME cursor position to prevent Chinese input flickering
- **TextField cursor**: Correct cursor position with multiple consecutive newlines
- **Windows input**: Restore `ENABLE_PROCESSED_INPUT` so Ctrl+C generates SIGINT
- **Windows input**: Cap the input loop wait so timers and signals fire reliably
- **Win32 input**: Encode `KEY_EVENT_RECORD.uChar` as UTF-8 for correct IME input
- **Win32 mouse**: Forward bare mouse motion as SGR button 35 so hover works
- **Character width**: Keep East Asian Ambiguous punctuation single-width
- **Selection**: Edge auto-scroll during selection drag in scroll views
- **Terminal shutdown**: Stop sending DECRDA query on TUI shutdown
- **Project paths**: Terminate `getProjectDirectory` walk at Windows drive roots
- **TextField**: Use `InputDecoration` instead of `BoxDecoration`

## Refactoring
- **Character width**: Delegate CJK classification to the xterm wcwidth table

## Chores
- **CI**: Bump GitHub Actions to node24-compatible majors
- Strengthen the test suite with additional matchers, audit fixes, and gap coverage

---

# 0.7.0

## Layout pipeline

The layout-skip check now uses value equality on constraints instead of
`identical()`, and every core mutation path marks layout explicitly. Apps
get strictly fewer redundant relayouts than 0.6.0 (which effectively
re-laid out the full tree every frame), while content updates render
reliably.

## Bug Fixes
- **Overlay/Stack positioning**: Mark parent dirty when applying Positioned parent data, including the copy-in-place path used inside Overlay/Navigator (fixes overlay children frozen at stale positions)
- **Padding/Align**: Convert RenderPadding and RenderPositionedBox to compare-and-mark setters so padding/alignment changes re-layout (fixes stale layout when constraints are unchanged)
- **Child reorder**: Mark layout when moving render children, so reordering const/keyed children in Row/Column/Stack takes effect
- **ListView/LayoutBuilder**: Always mark layout in update() — a stable (hoisted) builder reading mutated state now re-renders instead of pinning stale content
- **ListView**: Evict stale separator cache entries when itemCount shrinks
- **Element slots**: Propagate slot changes for identity-equal components, so reordering const children updates paint order
- **Ticker**: Skip tail reschedule when onTick stops and restarts the ticker (fixes orphaned frame callbacks with AnimationController status listeners)
- **Selection**: Notify listeners on selection drag state mutations so list viewports repaint selection bands

## New APIs
- **EdgeInsets**: Value equality (`==`/`hashCode`), matching Flutter semantics

## Performance
- **Render pipeline**: markNeedsLayout/markNeedsPaint are idempotent — already-dirty nodes short-circuit instead of re-walking to the root

## Example
- Interactive `relayout_fixes_demo.dart` exercising the layout-mark paths, with an e2e smoke test

---

# 0.6.0

## New Features
- **Windows Support**: Add Windows platform support with Console API input for arrow keys and special keys
- **Shift+Enter Newline**: Support Shift+Enter for newline input via kitty keyboard protocol
- **Benchmark Suite**: Add benchmark suite with baseline comparison and CI workflow
- **Smart Markdown Tables**: Wrap markdown tables to fit terminal width

## Bug Fixes
- **Theme Colors**: Soften onBackground/onSurface theme colors to match terminal defaults; use explicit theme colors for fg/bg
- **Kitty Protocol**: Restore 0x0A as Enter and fix kitty sub-parameter parsing; include kitty/modifyOtherKeys in EscapeCodes values lists
- **Scroll Views**: Guard against non-finite sizes in scroll views and improve error rendering
- **Scrollbar**: Prevent scrollbar thumb from overlapping arrows at start/end
- **Terminal Exit**: Flush stdout before exit to prevent broken terminal state on macOS
- **Markdown**: Trim trailing newlines from last markdown block element
- **Element Comparison**: Use `operator==` instead of `identical` (matching Flutter)

## Performance
- **Inherited Element**: Skip redundant rebuilds in inherited element updates

## Refactoring
- **InheritedElement**: Make InheritedElement extend ProxyElement

## Chores
- Improve pub.dev score (description, changelog, example, lint)
- Add community section to README

---

# 0.5.1

## Bug Fixes
- **SingleChildScrollView**: Should shrink-wrap to child size instead of expanding
- **Selection**: Use screen position sorting for all viewports
- **Render Object**: Fix attach lifecycle
- **Shutdown**: Cancel pendingFrameTimer on shutdown to prevent dangling timers

---

# 0.5.0

## New Features
- **Text Selection**: Full text selection support with mouse drag, copy to clipboard, and visual highlight
- **TextField Mouse Interaction**: Click to position cursor and drag to select text

## Bug Fixes
- **Selection Cleanup**: Clean up drag state on unmount and exit
- **Scrollbar Position**: Fix scrollbar thumb positioning

---

# 0.4.4

## New Features
- **Backend Parameter**: Add optional backend parameter to `runApp` for custom terminal backends

---

# 0.4.3

## New Features
- **Image Protocol Support**: Implement image rendering in the terminal using the Kitty graphics protocol (experimental)

## Bug Fixes
- **Color Quantization**: Quantize colors in environments without true color support for better compatibility
- **Web Backend**: Fix input handling and debug overlay stack fit issues

## Documentation
- **Image Documentation**: Add documentation for image support and mark as experimental
- **Website**: Add nocterm.dev website link to README

## Refactoring
- **Internal**: Use built-in `getElementForInheritedComponentOfExactType` for cleaner code

## Testing
- **CI Fix**: Fix unicode block encoder tests for CI environment

---

# 0.4.2

## Bug Fixes
- **Refactor**: Use built-in `getElementForInheritedComponentOfExactType` for cleaner code

---

# 0.4.1

## Bug Fixes
- **Test cleanup**: Remove unused variable in test

---

# 0.4.0

## Major Features

### Developer Tools
- **DebugOverlay**: New debug overlay toggled with `Ctrl+G` showing real-time FPS, build/layout/paint timings, memory usage, and CPU usage
- **FrameRate presets**: New `FrameRate` class with common presets (fps30, fps60, fps120, unlimited)

### Scrolling Improvements
- **keyboardScrollable**: New property on `ListView` and `SingleChildScrollView` to enable built-in arrow key scrolling
- **cacheExtent**: New `cacheExtent` property on `ListView` for smoother scrolling with pre-rendered items
- **Offset caching**: Performance optimization for variable-height ListView items

### UI Components
- **Tint widget**: New widget for applying color tints to children
- **ModalBarrier.obscure**: New property to control barrier visibility
- **ColoredBox.obscure**: Consistent obscure support across box widgets
- **BoxConstraints equality**: Added `==` operator for constraint comparison

### Animation
- **ColorTween**: New tween for animating between colors
- **Color.lerp**: Linear interpolation support for colors

## Performance Improvements
- **Paint phase optimization**: Skip paint phase when nothing visual changed
- **ListView cache optimization**: Smarter cache invalidation to avoid excessive rebuilds
- **Relayout on resize**: Proper relayout when terminal constraints change
- **Reduced idle CPU**: Removed forced relayout hack

## Bug Fixes
- **ListView parent data**: Refactored to use parent data for layout offsets
- **Scroll bounds**: Improved ListView scroll bounds clamping
- **Wide character rendering**: Fixed zero-width space handling
- **Scroll lag**: Resolved O(n) ListView performance issues
- **Debug overflow indicator**: Disabled by default
- **Markdown tables**: Use unicode display width for column calculations
- **Analyzer warnings**: Resolved various warnings and unused code

---

# 0.3.5

## Bug Fixes
- **GestureDetector**: Fixed tap not working in ListView and with centered content

---

# 0.3.4

## Bug Fixes
- **Frame rate**: Respect frame rate limiting in TerminalBinding

---

# 0.3.3

## Features
- **BorderTitle rich text**: Added rich text support to border titles
- **Clipping**: Implemented proper clipping in `RenderStack` and `Container`
- **New components**: Added `ClipRect`, `OverflowBox`, and `SizedOverflowBox`

## Bug Fixes
- **Input freeze**: Fixed input freeze from rapid key sequences
- **Mouse wheel**: Fixed stacking order issues with mouse wheel events

---

# 0.3.2

## Bug Fixes
- **Package publishing**: Include `lib/src/third_party` in published package

---

# 0.3.1

## Bug Fixes
- **Multi-child containers**: Pass slot through ProxyElement to maintain child order
- **Stack repaint**: Implement `invokeLayoutCallback` to fix Stack repaint bug

---

# 0.3.0

## Major Features

### Animation System
- **Flutter-like animations**: Complete animation system with `AnimationController`, `Animation`, `Tween`, `Curves`
- **Ticker system**: Proper `Ticker` and `TickerProvider` for frame-based animations
- **AnimatedBuilder**: Widget that rebuilds on animation changes
- **SingleTickerProviderStateMixin**: Mixin for state classes that need animation support

### New Components
- **AsciiText**: Large ASCII art text renderer with extensible font system
  - Built-in fonts: `standard`, `banner`, `block`, `slim`
  - Custom font support via `AsciiFont` extension
- **Builder**: Simple component for inline building (like Flutter's Builder)

### TextField Improvements
- **onKeyEvent callback**: Intercept key events before TextField processes them

## Bug Fixes
- **Overlay state**: Prevent setState call on unmounted OverlayState

## Infrastructure
- **Release workflow**: Automated pub.dev publishing with OIDC
- **Version management**: Enhanced release workflow with custom version and README updates

---

# 0.2.0

## Highlights

This is a **major release** with 100+ commits introducing foundational changes for theming, performance, web support, and developer experience.

### Comprehensive Theming System
- **6 built-in themes**: dark, light, nord, dracula, catppuccin, gruvbox
- **Auto-detection**: Terminal brightness detection via OSC 11, COLORFGBG, and macOS Dark Mode
- New `TuiThemeData`, `TuiColors`, and `TuiTheme` InheritedComponent
- Added `onSuccess` and `onWarning` colors for complete status color pairs

### Differential Rendering (Major Performance Boost)
- Partial rendering that only updates cells that changed since previous frame
- Cell equality comparison (char + style) with previous frame buffer tracking
- Dramatically reduces terminal output for mostly static UIs

### Web Platform Support (Experimental)
- New `WebBackend` abstraction for running in browsers
- Extracted Terminal backend architecture for platform flexibility
- xterm.dart integration experiments

### Monorepo Architecture
- **Melos** for monorepo management with standardized scripts (test, analyze, format, clean)
- New `provider` package for state management
- New `nested` package for organization
- SDK constraint updated to `>=3.5.0`

## Major Features

### UI Components
- **LayoutBuilder**: Constraint-aware layouts (Flutter-like) for responsive designs
- **ValueListenableBuilder**: Reactive widget for `ValueListenable`
- **Rectangle class**: Exposed for geometry operations
- **Border titles**: `BoxDecoration` now supports title property
- **Opacity/Alpha blending**: Proper transparency support
- **Clipping**: Implement clipping with riverpod provider assertions
- **ensureVisible**: Auto-scroll support for ScrollViews

### Input
- **Soft-wrapping TextField**: Text wrapping, selection, and clipboard support
- **SIGINT handling**: Proper Ctrl+C signal handling

### Terminal Features
- **Terminal Color API**: Get/set API with extended OSC handling
- **Service extensions**: Debugging tools including rainbow paint

### CLI & Developer Experience
- **compile command**: Compile and restore shell commands in CLI
- **Args package**: CLI argument parsing
- **Hot reload debounce**: Prevents rapid reload spam
- **HTTP logging**: Logs exposed via HTTP server instead of `log.txt`
- **Pre-commit hook**: Auto-format on commit

### Documentation
- **Full documentation site** at docs.nocterm.dev (Fumadocs + GitHub Pages)
- Updated README with proper badges and guides

## Performance Improvements
- **Differential rendering**: Only redraws changed cells between frames
- **No-flush optimization**: Reduced unnecessary flushes
- **Better frame scheduling**: Smoother animations

## Bug Fixes

### Critical Fixes
- **Center widget**: Now properly expands within bounded constraints (was incorrectly shrinking)
- **Ctrl+C in TextField**: App is now properly quittable again
- **Hot reload assertion**: Fixed crashes during hot reload

### Rendering Fixes
- Fixed unconnected borders in BoxDecoration
- Fixed markdown rendering and nested list items
- Improved emoji handling (including FEOF emojis)

### Other Fixes
- Navigator test stale context (now uses GlobalKey)
- Stateful component inheritance
- TextField `onChange` text mutation issues
- Shell command exceptions
- Frame buffer null assertion removal

## Refactoring & Maintenance
- Hot reload architecture cleanup with shareable classes
- Code organization with proper command classes
- Extensive linting and formatting passes
- Added pubignore for cleaner publishing
- Third-party license notice for Flutter code

---

# 0.1.0

## Breaking Changes

### ListView
- **BREAKING**: Removed automatic keyboard navigation from ListView. Applications must now manually wrap ListView in Focusable for keyboard support:
  ```dart
  // Before (0.0.1)
  ListView(children: [...])

  // After (0.1.0)
  Focusable(
    onKeyEvent: (event) { /* handle navigation */ },
    child: ListView(children: [...]),
  )
  ```

### TextField
- **BREAKING**: Removed automatic tap-to-focus behavior. Manual focus management now required for tap interactions.

## Major Features

### State Management
- **Riverpod Integration**: Complete Riverpod state management with ProviderScope, reactive widgets, and full provider API support
- **Render Theater**: New overlay management system with optimized paint ordering and hit testing
- **Provider Dependencies**: Sophisticated subscription management for reactive UI updates

### UI Components
- **Stack Widget**: Overlapping layout support with positioned/non-positioned children
- **ConstrainedBox**: Min/max width/height constraints for precise layout control
- **Markdown Support**: Rich text rendering with headers, lists, code blocks, tables, and links

### Navigation
- **Overlay System**: Complete navigator rewrite using overlay-based architecture
- **Route Replacement**: New pushReplacement methods for better navigation flow
- **Navigator Improvements**: Enhanced route management and lifecycle handling

## Performance Improvements
- **Terminal Output**: Write buffering dramatically reduces system calls
- **ListView CPU Fix**: Fixed 100% CPU usage with proper change detection
- **Event Processing**: Eliminated keyboard event spam from unparseable mouse events
- **Performance Tests**: Added benchmark suite for regression testing

## Scrolling Enhancements
- **RenderObject Scrolling**: Moved scrolling logic to RenderObject layer for better performance
- **Mouse Support**: Full mouse wheel scrolling with SGR coordinate tracking
- **Auto-Scroll**: Smart auto-scrolling for chat/log interfaces
- **Reverse Mode**: ListView reverse option for chat-like UIs
- **Improved Metrics**: Better scroll extent calculation for variable-height items

## Visual Improvements
- **Modern Colors**: Updated color palette with sophisticated muted tones
- **Cursor Styles**: Enhanced text field cursor customization
- **Text Wrapping**: Proper text wrapping in columns with cross-axis stretch

## Bug Fixes
- Fixed multi-child rebuild layout issues
- Fixed column-in-column constraint handling
- Fixed render object handling for Expanded widgets
- Fixed ESC key handling
- Fixed ordering bugs with Row/Column non-RenderObject elements
- Fixed constraints in flexible layouts and Align widgets
- Improved error handling and hot reload logging

## Architecture
- Clean separation of display and input concerns
- Enhanced lifecycle management for components
- Improved render object system with better layout calculations
- Comprehensive test coverage with visual validation


# 0.0.1

- Initial version.