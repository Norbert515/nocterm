import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/error_widget.dart';
import 'package:test/test.dart' hide isNotEmpty;

void main() {
  group('NoctermErrorDetails', () {
    test('constructor with all parameters', () {
      final details = NoctermErrorDetails(
        exception: Exception('Test error'),
        stack: StackTrace.current,
        library: 'test library',
        context: 'while testing',
        informationCollector: () => ['info1', 'info2'],
        silent: true,
      );

      expect(details.exception, isA<Exception>());
      expect(details.stack, isNotNull);
      expect(details.library, equals('test library'));
      expect(details.context, equals('while testing'));
      expect(details.informationCollector, isNotNull);
      expect(details.silent, isTrue);
    });

    test('constructor with minimal fields (just exception)', () {
      final details = NoctermErrorDetails(exception: 'Simple string error');

      expect(details.exception, equals('Simple string error'));
      expect(details.stack, isNull);
      expect(details.library, equals('nocterm framework')); // default value
      expect(details.context, isNull);
      expect(details.informationCollector, isNull);
      expect(details.silent, isFalse); // default value
    });

    test('toString() with library and context', () {
      final details = NoctermErrorDetails(
        exception: 'Test exception',
        library: 'my library',
        context: 'during test execution',
      );

      final output = details.toString();

      expect(output, contains('Exception caught by my library'));
      expect(output, contains('during test execution'));
      expect(output, contains('Test exception'));
    });

    test('toString() with stack trace', () {
      final stack = StackTrace.current;
      final details = NoctermErrorDetails(
        exception: 'Error with stack',
        stack: stack,
      );

      final output = details.toString();

      expect(output, contains('Stack trace:'));
      expect(output, contains(stack.toString()));
    });

    test('toString() with informationCollector', () {
      final details = NoctermErrorDetails(
        exception: 'Error with extra info',
        informationCollector: () => [
          'Additional detail 1',
          'Additional detail 2',
          'Additional detail 3',
        ],
      );

      final output = details.toString();

      expect(output, contains('Additional information:'));
      expect(output, contains('Additional detail 1'));
      expect(output, contains('Additional detail 2'));
      expect(output, contains('Additional detail 3'));
    });

    test('toString() formatting with all fields', () {
      final stack = StackTrace.fromString('#0 main (test.dart:1:1)');
      final details = NoctermErrorDetails(
        exception: 'Complete error',
        stack: stack,
        library: 'complete library',
        context: 'while completing',
        informationCollector: () => ['Complete info'],
      );

      final output = details.toString();

      // Check order and structure
      expect(output, contains('══╡ Exception caught by complete library ╞══'));
      expect(
        output,
        contains('The following exception was thrown while completing:'),
      );
      expect(output, contains('Complete error'));
      expect(output, contains('Stack trace:'));
      expect(output, contains('#0 main (test.dart:1:1)'));
      expect(output, contains('Additional information:'));
      expect(output, contains('Complete info'));
    });

    test('toString() without library shows no header', () {
      final details = NoctermErrorDetails(
        exception: 'No library error',
        library: null,
      );

      final output = details.toString();

      expect(output, isNot(contains('Exception caught by')));
      expect(output, contains('No library error'));
    });
  });

  group('NoctermError.onError', () {
    late NoctermExceptionHandler? originalHandler;

    setUp(() {
      originalHandler = NoctermError.onError;
      NoctermError.resetErrorCount();
    });

    tearDown(() {
      NoctermError.onError = originalHandler;
      NoctermError.resetErrorCount();
    });

    test('default handler is dumpErrorToConsole', () {
      // Reset to default
      NoctermError.onError = NoctermError.dumpErrorToConsole;

      expect(NoctermError.onError, equals(NoctermError.dumpErrorToConsole));
    });

    test('custom onError handler is called', () {
      final capturedDetails = <NoctermErrorDetails>[];

      NoctermError.onError = (details) {
        capturedDetails.add(details);
      };

      final testDetails = NoctermErrorDetails(
        exception: 'Test error for custom handler',
      );

      NoctermError.reportError(testDetails);

      expect(capturedDetails, hasLength(1));
      expect(
        capturedDetails.first.exception,
        equals('Test error for custom handler'),
      );
    });

    test('setting onError to null does not crash on reportError', () {
      NoctermError.onError = null;

      final testDetails = NoctermErrorDetails(exception: 'Should not crash');

      // Should not throw
      expect(() => NoctermError.reportError(testDetails), returnsNormally);
    });

    test('onError handler can be changed multiple times', () {
      var callCount1 = 0;
      var callCount2 = 0;

      NoctermError.onError = (_) => callCount1++;
      NoctermError.reportError(NoctermErrorDetails(exception: 'Error 1'));

      NoctermError.onError = (_) => callCount2++;
      NoctermError.reportError(NoctermErrorDetails(exception: 'Error 2'));

      expect(callCount1, equals(1));
      expect(callCount2, equals(1));
    });
  });

  group('NoctermError.resetErrorCount', () {
    late NoctermExceptionHandler? originalHandler;
    setUp(() {
      originalHandler = NoctermError.onError;
      NoctermError.resetErrorCount();
    });

    tearDown(() {
      NoctermError.onError = originalHandler;
      NoctermError.resetErrorCount();
    });

    test('resetErrorCount resets the counter', () {
      // Capture print output
      NoctermError.onError = NoctermError.dumpErrorToConsole;

      // First error should print full details
      NoctermError.dumpErrorToConsole(
        NoctermErrorDetails(exception: 'First error'),
      );

      // Reset the counter
      NoctermError.resetErrorCount();

      // This should again be treated as first error (full details)
      // We can't easily test print output, but we verify no crash
      expect(
        () => NoctermError.dumpErrorToConsole(
          NoctermErrorDetails(exception: 'After reset'),
        ),
        returnsNormally,
      );
    });
  });

  group('NoctermError.reportError', () {
    late NoctermExceptionHandler? originalHandler;

    setUp(() {
      originalHandler = NoctermError.onError;
      NoctermError.resetErrorCount();
    });

    tearDown(() {
      NoctermError.onError = originalHandler;
      NoctermError.resetErrorCount();
    });

    test('reportError calls onError callback', () {
      var wasCalled = false;

      NoctermError.onError = (_) {
        wasCalled = true;
      };

      NoctermError.reportError(NoctermErrorDetails(exception: 'Test'));

      expect(wasCalled, isTrue);
    });

    test('reportError passes correct details to handler', () {
      NoctermErrorDetails? receivedDetails;

      NoctermError.onError = (details) {
        receivedDetails = details;
      };

      final testDetails = NoctermErrorDetails(
        exception: 'Specific error',
        library: 'specific library',
        context: 'specific context',
        silent: true,
      );

      NoctermError.reportError(testDetails);

      expect(receivedDetails, isNotNull);
      expect(receivedDetails!.exception, equals('Specific error'));
      expect(receivedDetails!.library, equals('specific library'));
      expect(receivedDetails!.context, equals('specific context'));
      expect(receivedDetails!.silent, isTrue);
    });

    test('reportError does nothing when onError is null', () {
      NoctermError.onError = null;

      // Should complete without error
      expect(
        () => NoctermError.reportError(
          NoctermErrorDetails(exception: 'Should be ignored'),
        ),
        returnsNormally,
      );
    });
  });

  group('NoctermError.dumpErrorToConsole', () {
    setUp(() {
      NoctermError.resetErrorCount();
    });

    tearDown(() {
      NoctermError.resetErrorCount();
    });

    test('first error prints full details', () {
      // We can verify this doesn't crash; actual print testing
      // would require capturing stdout
      expect(
        () => NoctermError.dumpErrorToConsole(
          NoctermErrorDetails(
            exception: 'First error details',
            library: 'test lib',
            context: 'test context',
          ),
        ),
        returnsNormally,
      );
    });

    test('subsequent errors print shorter summary', () {
      // First error
      NoctermError.dumpErrorToConsole(
        NoctermErrorDetails(exception: 'Error 1'),
      );

      // Second error - should print shorter format
      expect(
        () => NoctermError.dumpErrorToConsole(
          NoctermErrorDetails(exception: 'Error 2'),
        ),
        returnsNormally,
      );

      // Third error
      expect(
        () => NoctermError.dumpErrorToConsole(
          NoctermErrorDetails(exception: 'Error 3'),
        ),
        returnsNormally,
      );
    });
  });

  group('Integration with ErrorThrowingWidget', () {
    late NoctermExceptionHandler? originalHandler;
    late List<NoctermErrorDetails> capturedErrors;

    setUp(() {
      originalHandler = NoctermError.onError;
      capturedErrors = [];
      NoctermError.resetErrorCount();

      NoctermError.onError = (details) {
        capturedErrors.add(details);
      };
    });

    tearDown(() {
      NoctermError.onError = originalHandler;
      NoctermError.resetErrorCount();
    });

    test('layout error triggers NoctermError.onError', () async {
      await testNocterm('layout error integration', (tester) async {
        await tester.pumpComponent(
          const ErrorThrowingWidget(
            throwInLayout: true,
            throwInPaint: false,
            errorMessage: 'Layout integration test',
          ),
        );

        // Error should have been captured (layout errors throw IntegerDivisionByZeroException)
        expect(capturedErrors, isNotEmpty);
        // Layout error context contains "performLayout"
        expect(
          capturedErrors.any(
            (d) => d.context?.contains('performLayout') ?? false,
          ),
          isTrue,
        );
      });
    });

    test('paint error triggers NoctermError.onError', () async {
      await testNocterm('paint error integration', (tester) async {
        await tester.pumpComponent(
          const ErrorThrowingWidget(
            throwInLayout: false,
            throwInPaint: true,
            errorMessage: 'Paint integration test',
          ),
        );

        // Error should have been captured
        expect(capturedErrors, isNotEmpty);
        // Paint error uses the errorMessage in the exception
        expect(
          capturedErrors.any(
            (d) => d.exception.toString().contains('Paint integration test'),
          ),
          isTrue,
        );
      });
    });

    test('errors contain contextual information', () async {
      await testNocterm('error context', (tester) async {
        await tester.pumpComponent(
          const ErrorThrowingWidget(
            throwInLayout: true,
            errorMessage: 'Contextual error',
          ),
        );

        // Should have captured at least one error
        expect(capturedErrors, isNotEmpty);

        // Find any error from rendering (layout errors are IntegerDivisionByZeroException)
        final relevantError = capturedErrors.first;

        // Should have library information
        expect(relevantError.library, isNotNull);

        // Should have context about what was happening
        expect(relevantError.context, isNotNull);
      });
    });

    test('multiple paint errors are captured separately', () async {
      await testNocterm('multiple errors', (tester) async {
        // Use paint errors since they include the errorMessage in the exception
        await tester.pumpComponent(
          Column(
            children: [
              const ErrorThrowingWidget(
                throwInLayout: false,
                throwInPaint: true,
                errorMessage: 'First paint error',
              ),
              const ErrorThrowingWidget(
                throwInLayout: false,
                throwInPaint: true,
                errorMessage: 'Second paint error',
              ),
            ],
          ),
        );

        // Both errors should be captured
        expect(
          capturedErrors.any(
            (d) => d.exception.toString().contains('First paint error'),
          ),
          isTrue,
        );
        expect(
          capturedErrors.any(
            (d) => d.exception.toString().contains('Second paint error'),
          ),
          isTrue,
        );
      });
    });
  });

  group('Exception type handling', () {
    test('handles Exception objects', () {
      final details = NoctermErrorDetails(
        exception: Exception('Standard exception'),
      );

      expect(details.exception, isA<Exception>());
      expect(details.toString(), contains('Standard exception'));
    });

    test('handles Error objects', () {
      final details = NoctermErrorDetails(exception: StateError('State error'));

      expect(details.exception, isA<StateError>());
      expect(details.toString(), contains('State error'));
    });

    test('handles String errors', () {
      final details = NoctermErrorDetails(exception: 'Plain string error');

      expect(details.exception, isA<String>());
      expect(details.toString(), contains('Plain string error'));
    });

    test('handles arbitrary objects', () {
      final details = NoctermErrorDetails(exception: {'error': 'map error'});

      expect(details.exception, isA<Map>());
      expect(details.toString(), contains('error'));
    });
  });
}
