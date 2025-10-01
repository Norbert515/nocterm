# Nocterm Changes log

## 0.1.1

- Provide wrapper for Window's platform's terminal`stdin` so that it behaves as a 'standard' unix style terminal in
  regards to sending mouse and keyboard key events as ANSI CSI sequences.
  
## 0.1.0

### Breaking Changes

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

### Major Features

#### State Management

- **Riverpod Integration**: Complete Riverpod state management with ProviderScope, reactive widgets, and full provider API support
- **Render Theater**: New overlay management system with optimized paint ordering and hit testing
- **Provider Dependencies**: Sophisticated subscription management for reactive UI updates

#### UI Components

- **Stack Widget**: Overlapping layout support with positioned/non-positioned children
- **ConstrainedBox**: Min/max width/height constraints for precise layout control
- **Markdown Support**: Rich text rendering with headers, lists, code blocks, tables, and links

#### Navigation

- **Overlay System**: Complete navigator rewrite using overlay-based architecture
- **Route Replacement**: New pushReplacement methods for better navigation flow
- **Navigator Improvements**: Enhanced route management and lifecycle handling

#### Performance Improvements

- **Terminal Output**: Write buffering dramatically reduces system calls
- **ListView CPU Fix**: Fixed 100% CPU usage with proper change detection
- **Event Processing**: Eliminated keyboard event spam from unparseable mouse events
- **Performance Tests**: Added benchmark suite for regression testing

#### Scrolling Enhancements

- **RenderObject Scrolling**: Moved scrolling logic to RenderObject layer for better performance
- **Mouse Support**: Full mouse wheel scrolling with SGR coordinate tracking
- **Auto-Scroll**: Smart auto-scrolling for chat/log interfaces
- **Reverse Mode**: ListView reverse option for chat-like UIs
- **Improved Metrics**: Better scroll extent calculation for variable-height items

#### Visual Improvements

- **Modern Colors**: Updated color palette with sophisticated muted tones
- **Cursor Styles**: Enhanced text field cursor customization
- **Text Wrapping**: Proper text wrapping in columns with cross-axis stretch

#### Bug Fixes

- Fixed multi-child rebuild layout issues
- Fixed column-in-column constraint handling
- Fixed render object handling for Expanded widgets
- Fixed ESC key handling
- Fixed ordering bugs with Row/Column non-RenderObject elements
- Fixed constraints in flexible layouts and Align widgets
- Improved error handling and hot reload logging

#### Architecture

- Clean separation of display and input concerns
- Enhanced lifecycle management for components
- Improved render object system with better layout calculations
- Comprehensive test coverage with visual validation

## 0.0.1

- Initial version.
