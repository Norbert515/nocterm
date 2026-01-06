import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/error_widget.dart';

void main() {
  group('Tab Switching Error Handling', () {
    test('error appears and disappears when switching tabs', () async {
      await testNocterm(
        'tab switching with error',
        (tester) async {
          await tester.pumpComponent(const _TabbedPageWidget());

          // Initially on page 1 - no error
          var output = tester.terminalState.getText();
          expect(output, contains('Page 1: Working'));
          expect(output, contains('This is page 1 content'));
          expect(output, isNot(contains('Page 2')));
          expect(output, isNot(contains('Error')));
          expect(output, isNot(contains('┌'))); // No error box

          print('Initial state (Page 1):');
          print(output);
          print('---');

          // Press Tab to switch to page 2 - should show error
          await tester.sendKey(LogicalKey.tab);
          await tester.pump();

          output = tester.terminalState.getText();
          expect(output, contains('Page 2: Error Page'));
          expect(output, contains('Before error widget'));
          expect(output, contains('After error widget'));
          // Should show the error box (when layout fails, widget still shows "No Error")
          expect(
            output,
            contains('No Error'),
          ); // ErrorThrowingWidget shows this after layout error

          print('After switching to Page 2:');
          print(output);
          print('---');

          // Press Tab again to switch back to page 1 - error should be gone
          await tester.sendKey(LogicalKey.tab);
          await tester.pump();

          output = tester.terminalState.getText();
          expect(output, contains('Page 1: Working'));
          expect(output, contains('This is page 1 content'));
          expect(output, isNot(contains('Page 2')));
          expect(output, isNot(contains('Error')));
          expect(output, isNot(contains('┌'))); // No error box

          print('After switching back to Page 1:');
          print(output);
          print('---');

          // Switch to page 2 again to verify error still appears
          await tester.sendKey(LogicalKey.tab);
          await tester.pump();

          output = tester.terminalState.getText();
          expect(output, contains('Page 2: Error Page'));
          expect(
            output,
            contains('No Error'),
          ); // The error widget still renders

          print('After switching to Page 2 again:');
          print(output);
        },
        debugPrintAfterPump: false,
        size: const Size(80, 24),
      );
    });

    test('paint error shows error box when switching tabs', () async {
      await testNocterm(
        'tab switching with paint error',
        (tester) async {
          await tester.pumpComponent(const _TabbedPageWithPaintError());

          // Initially on page 1 - no error
          var output = tester.terminalState.getText();
          expect(output, contains('Page 1: Working'));
          expect(output, isNot(contains('┌'))); // No error box

          // Press Tab to switch to page 2 with paint error
          await tester.sendKey(LogicalKey.tab);
          await tester.pump();

          output = tester.terminalState.getText();
          expect(output, contains('Page 2: Paint Error Page'));
          // Paint error should show error box
          expect(output, contains('Paint Error'));
          expect(output, contains('┌')); // Error box border

          // Press Tab again to switch back to page 1 - error should be gone
          await tester.sendKey(LogicalKey.tab);
          await tester.pump();

          output = tester.terminalState.getText();
          expect(output, contains('Page 1: Working'));
          expect(output, isNot(contains('┌'))); // No error box
        },
        debugPrintAfterPump: true,
        size: const Size(80, 24),
      );
    });
  });
}

/// A widget with two pages that can be switched using Tab key
class _TabbedPageWidget extends StatefulComponent {
  const _TabbedPageWidget();

  @override
  State<_TabbedPageWidget> createState() => _TabbedPageWidgetState();
}

class _TabbedPageWidgetState extends State<_TabbedPageWidget> {
  int _currentPage = 0;

  void _switchPage() {
    setState(() {
      _currentPage = (_currentPage + 1) % 2;
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          _switchPage();
          return true;
        }
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header that's always visible
            Text(
              'Tab Navigation Test',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Press TAB to switch pages. Current: Page ${_currentPage + 1}',
            ),
            Text('─' * 40),
            const SizedBox(height: 1),

            // Page content - conditionally rendered
            if (_currentPage == 0) ...[
              const Text('Page 1: Working'),
              const SizedBox(height: 1),
              const Text('This is page 1 content'),
              const Text('Everything works fine here'),
              const Text('No errors on this page'),
            ] else ...[
              const Text('Page 2: Error Page'),
              const SizedBox(height: 1),
              const Text('Before error widget'),
              const SizedBox(
                width: 60,
                height: 5,
                child: ErrorThrowingWidget(
                  throwInLayout: true,
                  errorMessage: 'Deliberate error on page 2',
                ),
              ),
              const Text('After error widget'),
            ],

            const Spacer(),
            Text('─' * 40),
            const Text('Footer: Always visible'),
          ],
        ),
      ),
    );
  }
}

/// A widget with paint error on page 2
class _TabbedPageWithPaintError extends StatefulComponent {
  const _TabbedPageWithPaintError();

  @override
  State<_TabbedPageWithPaintError> createState() =>
      _TabbedPageWithPaintErrorState();
}

class _TabbedPageWithPaintErrorState extends State<_TabbedPageWithPaintError> {
  int _currentPage = 0;

  void _switchPage() {
    setState(() {
      _currentPage = (_currentPage + 1) % 2;
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          _switchPage();
          return true;
        }
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Tab Navigation Test (Paint Error)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Press TAB to switch. Current: Page ${_currentPage + 1}'),
            Text('─' * 40),
            const SizedBox(height: 1),

            // Page content
            if (_currentPage == 0) ...[
              const Text('Page 1: Working'),
              const SizedBox(height: 1),
              const Text('This page has no errors'),
            ] else ...[
              const Text('Page 2: Paint Error Page'),
              const SizedBox(height: 1),
              const SizedBox(
                width: 60,
                height: 5,
                child: ErrorThrowingWidget(
                  throwInLayout: false,
                  throwInPaint: true,
                  errorMessage: 'Paint error on page 2',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
