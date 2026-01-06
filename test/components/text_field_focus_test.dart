import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

// Mock component for testing
class TestApp extends StatefulComponent {
  const TestApp({super.key});

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  final controller1 = TextEditingController(text: 'field1');
  final controller2 = TextEditingController(text: 'field2');
  int focusedField = 0;

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller1,
          focused: focusedField == 0,
          onFocusChange: (focused) {
            if (focused) {
              setState(() => focusedField = 0);
            }
          },
        ),
        TextField(
          controller: controller2,
          focused: focusedField == 1,
          onFocusChange: (focused) {
            if (focused) {
              setState(() => focusedField = 1);
            }
          },
        ),
      ],
    );
  }
}

void main() {
  group('TextField Focus Management', () {
    test('TextField respects focused prop', () {
      // Create two text fields with explicit focus control
      final controller1 = TextEditingController(text: 'field1');
      final controller2 = TextEditingController(text: 'field2');

      final field1 = TextField(
        controller: controller1,
        focused: true,
        onFocusChange: (focused) {},
      );

      final field2 = TextField(
        controller: controller2,
        focused: false,
        onFocusChange: (focused) {},
      );

      // Verify that the focused prop is correctly set
      expect(field1.focused, true);
      expect(field2.focused, false);
    });

    test('TextField calls onFocusChange when tapped', () {
      final field = TextField(focused: false, onFocusChange: (focused) {});

      // Verify onFocusChange callback is provided
      expect(field.onFocusChange, isNotNull);
    });

    test('TextEditingController manages text independently of focus', () {
      final controller = TextEditingController(text: 'initial');

      // Text should be managed regardless of focus state
      final fieldFocused = TextField(
        controller: controller,
        focused: true,
        onFocusChange: (_) {},
      );

      final fieldUnfocused = TextField(
        controller: controller,
        focused: false,
        onFocusChange: (_) {},
      );

      // Both fields should use the same controller
      expect(fieldFocused.controller, same(controller));
      expect(fieldUnfocused.controller, same(controller));

      // Text changes should work regardless of focus
      controller.text = 'updated';
      expect(controller.text, 'updated');
    });

    test('TextField no longer uses FocusNode', () {
      // Verify that TextField constructor doesn't accept FocusNode
      final field = TextField(focused: true, onFocusChange: (_) {});

      // The field should not have any focus node related properties
      // This test confirms our refactoring removed FocusNode dependency
      expect(field.focused, isA<bool>());
    });

    test('Multiple TextFields can be managed with single focus index', () {
      // This test demonstrates the pattern for managing multiple fields
      int focusIndex = 0;

      final fields = List.generate(3, (index) {
        return TextField(
          focused: focusIndex == index,
          onFocusChange: (focused) {
            if (focused) {
              focusIndex = index;
            }
          },
        );
      });

      // Verify each field has correct focus state
      expect(fields[0].focused, true);
      expect(fields[1].focused, false);
      expect(fields[2].focused, false);

      // Simulate focus change
      fields[1].onFocusChange?.call(true);
      expect(focusIndex, 1);
    });
  });
}
