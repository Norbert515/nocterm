import 'dart:async';

import 'package:nocterm/nocterm.dart';

/// Main testing interface for TUI applications.
/// Provides methods for rendering frames, simulating input, and inspecting state.
class NoctermTester {
  NoctermTester._({
    required NoctermTestBinding binding,
    bool debugPrintAfterPump = false,
  })  : _binding = binding,
        _debugPrintAfterPump = debugPrintAfterPump;

  final NoctermTestBinding _binding;

  /// Whether to automatically print the terminal state after each pump
  bool _debugPrintAfterPump;

  /// Enable or disable debug printing after pump
  set debugPrintAfterPump(bool value) => _debugPrintAfterPump = value;

  /// Create a new TUI tester with optional size configuration
  static Future<NoctermTester> create({
    Size size = const Size(80, 24),
    bool debugPrintAfterPump = false,
  }) async {
    final binding = NoctermTestBinding(size: size);

    return NoctermTester._(
      binding: binding,
      debugPrintAfterPump: debugPrintAfterPump,
    );
  }

  /// Get the current terminal state
  TerminalState get terminalState {
    final buffer = _binding.lastBuffer;
    if (buffer == null) {
      throw StateError(
        'No frame has been rendered yet. Call pump() or pumpComponent() first.',
      );
    }

    return TerminalState(
      buffer: buffer,
      size: _binding.size,
    );
  }

  /// Get the number of frames that have been rendered
  int get frameCount => _binding.frameCount;

  /// Pump a component as the root of the tree
  Future<void> pumpComponent(Component component, [Duration? duration]) async {
    _binding.attachRootComponent(component);
    await pump(duration);
  }

  /// Pump a single frame
  Future<void> pump([Duration? duration]) async {
    await _binding.pump(duration);

    if (_debugPrintAfterPump && _binding.lastBuffer != null) {
      _printDebugOutput();
    }
  }

  /// Pump frames until no more frames are scheduled
  Future<void> pumpAndSettle([
    Duration duration = const Duration(milliseconds: 100),
    int maxIterations = 20,
  ]) async {
    await _binding.pumpAndSettle(duration, maxIterations);

    if (_debugPrintAfterPump && _binding.lastBuffer != null) {
      _printDebugOutput();
    }
  }

  /// Simulate typing text
  Future<void> enterText(String text) async {
    _binding.enterText(text);
    await pump();
  }

  /// Send a keyboard event
  Future<void> sendKeyEvent(KeyboardEvent event) async {
    _binding.sendKeyboardEvent(event);
    await pump();
  }

  /// Send a key press by logical key
  Future<void> sendKey(LogicalKey key) async {
    await sendKeyEvent(KeyboardEvent(
      logicalKey: key,
    ));
  }

  /// Send common key combinations
  Future<void> sendEnter() => sendKey(LogicalKey.enter);
  Future<void> sendEscape() => sendKey(LogicalKey.escape);
  Future<void> sendTab() => sendKey(LogicalKey.tab);
  Future<void> sendBackspace() => sendKey(LogicalKey.backspace);
  Future<void> sendDelete() => sendKey(LogicalKey.delete);
  Future<void> sendArrowUp() => sendKey(LogicalKey.arrowUp);
  Future<void> sendArrowDown() => sendKey(LogicalKey.arrowDown);
  Future<void> sendArrowLeft() => sendKey(LogicalKey.arrowLeft);
  Future<void> sendArrowRight() => sendKey(LogicalKey.arrowRight);

  /// Render the current state as a string for debugging
  String renderToString({bool showBorders = true}) {
    return terminalState.renderToString(showBorders: showBorders);
  }

  /// Get a snapshot string for comparison
  String toSnapshot() {
    return terminalState.toSnapshot();
  }

  /// Find a component in the tree by type
  T? findComponent<T extends Component>() {
    if (_binding.rootElement == null) return null;

    T? result;
    void visitor(Element element) {
      if (element.component is T) {
        result = element.component as T;
        return;
      }
      element.visitChildren(visitor);
    }

    visitor(_binding.rootElement!);
    return result;
  }

  /// Find all components of a specific type
  List<T> findAllComponents<T extends Component>() {
    if (_binding.rootElement == null) return [];

    final results = <T>[];
    void visitor(Element element) {
      if (element.component is T) {
        results.add(element.component as T);
      }
      element.visitChildren(visitor);
    }

    visitor(_binding.rootElement!);
    return results;
  }

  /// Clean up resources
  void dispose() {
    _binding.shutdown();
  }

  void _printDebugOutput() {
    print('\n╔═ Terminal Output ═══════════════════════════════════════════════════════════╗');
    final lines = renderToString(showBorders: false).split('\n');
    for (final line in lines) {
      // Pad or truncate line to fit within 78 chars
      final displayLine = line.length > 78 ? line.substring(0, 78) : line.padRight(78);
      print('║$displayLine║');
    }
    print('╚══════════════════════════════════════════════════════════════════════════════╝');
  }
}

/// Function signature for TUI test callbacks
typedef TuiTestCallback = Future<void> Function(NoctermTester tester);

/// Run a TUI test with automatic setup and teardown
Future<void> testNocterm(
  String description,
  TuiTestCallback callback, {
  Size size = const Size(80, 24),
  bool skip = false,
  bool debugPrintAfterPump = false,
  Duration? timeout,
}) async {
  if (skip) return;

  print('TEST: $description');

  final tester = await NoctermTester.create(
    size: size,
    debugPrintAfterPump: debugPrintAfterPump,
  );

  try {
    if (timeout != null) {
      await callback(tester).timeout(timeout);
    } else {
      await callback(tester);
    }
    print('  ✓ PASSED');
  } catch (e, stack) {
    print('  ✗ FAILED');
    print('    Error: $e');
    print('    Stack trace:\n$stack');
    rethrow;
  } finally {
    tester.dispose();
  }
}
