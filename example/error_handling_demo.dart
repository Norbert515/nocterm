/// NoctermError Demo
///
/// This demo showcases the NoctermError system for custom error handling.
/// It demonstrates:
/// 1. Setting up a custom error handler (like you would for Sentry integration)
/// 2. Triggering errors during widget build/layout
/// 3. Seeing the RenderTUIErrorBox visual feedback
///
/// Run with: dart run example/error_handling_demo.dart
library;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/error_widget.dart';

void main() async {
  // ============================================
  // CUSTOM ERROR HANDLER SETUP
  // ============================================
  // This is where you would integrate with Sentry, Crashlytics, etc.
  NoctermError.onError = (details) {
    // Simulate sending to Sentry
    print('');
    print('🚨 ═══════════════════════════════════════════════════════════ 🚨');
    print('🚨 CUSTOM ERROR HANDLER (simulating Sentry integration)       🚨');
    print('🚨 ═══════════════════════════════════════════════════════════ 🚨');
    print('');
    print('Library:   ${details.library ?? "unknown"}');
    print('Context:   ${details.context ?? "unknown"}');
    print('Exception: ${details.exception}');
    print('Silent:    ${details.silent}');
    print('');
    if (details.informationCollector != null) {
      print('Additional Info:');
      for (final info in details.informationCollector!()) {
        print('  $info');
      }
    }
    print('');
    print('// In production, you would call:');
    print(
      '// Sentry.captureException(details.exception, stackTrace: details.stack);',
    );
    print('');

    // Still dump to console for visibility
    NoctermError.dumpErrorToConsole(details);
  };

  // Run the demo app
  await runApp(const ErrorHandlingDemo());
}

/// Main demo application showing error handling
class ErrorHandlingDemo extends StatefulComponent {
  const ErrorHandlingDemo({super.key});

  @override
  State<ErrorHandlingDemo> createState() => _ErrorHandlingDemoState();
}

class _ErrorHandlingDemoState extends State<ErrorHandlingDemo> {
  ErrorType _currentError = ErrorType.none;
  int _errorCount = 0;
  String _lastError = 'None';

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          height: 3,
          decoration: BoxDecoration(border: BoxBorder.all(color: Colors.cyan)),
          child: Center(
            child: Text(
              'NoctermError Demo - Press keys to trigger errors',
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Main content
        Expanded(
          child: Row(
            children: [
              // Left panel - Controls
              Container(
                width: 40,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1),
                      child: Text(
                        'Controls',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Press a key to trigger:'),
                          const SizedBox(height: 1),
                          Text(
                            '  [1] Layout Error',
                            style: TextStyle(color: Colors.yellow),
                          ),
                          Text(
                            '  [2] Paint Error',
                            style: TextStyle(color: Colors.yellow),
                          ),
                          Text(
                            '  [3] Build Error (setState)',
                            style: TextStyle(color: Colors.yellow),
                          ),
                          Text(
                            '  [4] Manual Report',
                            style: TextStyle(color: Colors.yellow),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '  [R] Reset errors',
                            style: TextStyle(color: Colors.gray),
                          ),
                          Text(
                            '  [Q/Ctrl+C] Quit',
                            style: TextStyle(color: Colors.gray),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stats',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text('Errors triggered: $_errorCount'),
                          Text('Last error: $_lastError'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right panel - Error display area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.gray),
                  ),
                  child: Focusable(
                    focused: true,
                    onKeyEvent: _handleKeyEvent,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1),
                          child: Text(
                            'Error Display Area',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const Divider(),
                        Expanded(child: Center(child: _buildErrorWidget())),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Footer
        Container(
          height: 3,
          decoration: BoxDecoration(border: BoxBorder.all(color: Colors.gray)),
          child: Center(
            child: Text(
              'Check your terminal output for custom error handler messages',
              style: TextStyle(color: Colors.gray),
            ),
          ),
        ),
      ],
    );
  }

  Component _buildErrorWidget() {
    switch (_currentError) {
      case ErrorType.none:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No errors yet', style: TextStyle(color: Colors.gray)),
            const SizedBox(height: 1),
            Text(
              'Press 1-4 to trigger an error',
              style: TextStyle(color: Colors.gray),
            ),
          ],
        );

      case ErrorType.layout:
        // This widget throws during layout
        return const ErrorThrowingWidget(
          throwInLayout: true,
          throwInPaint: false,
          errorMessage: 'Deliberate layout error for demo',
        );

      case ErrorType.paint:
        // This widget throws during paint
        return const ErrorThrowingWidget(
          throwInLayout: false,
          throwInPaint: true,
          errorMessage: 'Deliberate paint error for demo',
        );

      case ErrorType.build:
        // Show a pre-rendered error box (simulating what happens after build error)
        return const TUIErrorWidget(
          message: 'Build error occurred',
          error: 'Widget build() threw an exception',
        );

      case ErrorType.manual:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Manual error reported!',
              style: TextStyle(color: Colors.yellow),
            ),
            const SizedBox(height: 1),
            Text(
              'Check terminal for handler output',
              style: TextStyle(color: Colors.gray),
            ),
          ],
        );
    }
  }

  bool _handleKeyEvent(event) {
    if (event.logicalKey == LogicalKey.digit1) {
      setState(() {
        _currentError = ErrorType.layout;
        _errorCount++;
        _lastError = 'Layout';
      });
      return true;
    } else if (event.logicalKey == LogicalKey.digit2) {
      setState(() {
        _currentError = ErrorType.paint;
        _errorCount++;
        _lastError = 'Paint';
      });
      return true;
    } else if (event.logicalKey == LogicalKey.digit3) {
      // Trigger error through NoctermError.reportError
      _errorCount++;
      _lastError = 'Build';
      NoctermError.reportError(
        NoctermErrorDetails(
          exception: StateError('Build phase error in widget'),
          library: 'nocterm framework',
          context: 'during widget build',
          informationCollector: () => [
            'Widget: ErrorHandlingDemo',
            'Parent: root',
            'Render object type: RenderColumn',
          ],
        ),
      );
      setState(() {
        _currentError = ErrorType.build;
      });
      return true;
    } else if (event.logicalKey == LogicalKey.digit4) {
      // Manually report an error
      _errorCount++;
      _lastError = 'Manual';
      NoctermError.reportError(
        NoctermErrorDetails(
          exception: Exception('Manually reported error for demo'),
          library: 'error_handling_demo',
          context: 'during manual error trigger',
          stack: StackTrace.current,
          informationCollector: () => [
            'This is a manually reported error',
            'Useful for catching errors in async callbacks',
            'Or errors from external libraries',
          ],
        ),
      );
      setState(() {
        _currentError = ErrorType.manual;
      });
      return true;
    } else if (event.logicalKey == LogicalKey.keyR) {
      setState(() {
        _currentError = ErrorType.none;
        _lastError = 'None (reset)';
      });
      NoctermError.resetErrorCount();
      return true;
    } else if (event.logicalKey == LogicalKey.keyQ) {
      return false; // Let it bubble up to exit
    }
    return false;
  }
}

enum ErrorType { none, layout, paint, build, manual }
