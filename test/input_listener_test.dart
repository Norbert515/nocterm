import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  late NoctermTester tester;

  tearDown(() {
    tester.dispose();
  });

  test('InputListener receives raw bytes via sendRawBytes', () async {
    tester = await NoctermTester.create(size: const Size(40, 10));

    final received = <List<int>>[];

    await tester.pumpComponent(
      InputListener(
        onInput: (bytes) {
          received.add(bytes);
          return true;
        },
        child: const Text('hello'),
      ),
    );

    await tester.sendRawBytes([0x68, 0x69]); // 'hi'

    expect(received, hasLength(1));
    expect(received.first, equals([0x68, 0x69]));
  });

  test('returning true consumes bytes — Focusable not called', () async {
    tester = await NoctermTester.create(size: const Size(40, 10));

    var focusableCalled = false;

    await tester.pumpComponent(
      InputListener(
        onInput: (bytes) => true, // consume everything
        child: Focusable(
          focused: true,
          onKeyEvent: (event) {
            focusableCalled = true;
            return true;
          },
          child: const Text('inner'),
        ),
      ),
    );

    // Send raw bytes for 'a' (0x61)
    await tester.sendRawBytes([0x61]);

    expect(focusableCalled, isFalse);
  });

  test('InputListener with no raw input allows keyboard events', () async {
    tester = await NoctermTester.create(size: const Size(40, 10));

    var focusableCalled = false;

    await tester.pumpComponent(
      InputListener(
        onInput: (bytes) => true,
        child: Focusable(
          focused: true,
          onKeyEvent: (event) {
            focusableCalled = true;
            return true;
          },
          child: const Text('inner'),
        ),
      ),
    );

    // Use sendKeyboardEvent (not sendRawBytes) — bypasses InputListener
    await tester.sendKey(LogicalKey.keyA);

    expect(focusableCalled, isTrue);
  });

  test('nested InputListeners — deepest-first wins', () async {
    tester = await NoctermTester.create(size: const Size(40, 10));

    var outerCalled = false;
    var innerCalled = false;

    await tester.pumpComponent(
      InputListener(
        onInput: (bytes) {
          outerCalled = true;
          return true;
        },
        child: InputListener(
          onInput: (bytes) {
            innerCalled = true;
            return true; // consumed by inner
          },
          child: const Text('nested'),
        ),
      ),
    );

    await tester.sendRawBytes([0x61]);

    expect(innerCalled, isTrue);
    expect(outerCalled, isFalse);
  });

  test('BlockFocus prevents raw input reaching InputListener', () async {
    tester = await NoctermTester.create(size: const Size(40, 10));

    var listenerCalled = false;

    await tester.pumpComponent(
      BlockFocus(
        blocking: true,
        child: InputListener(
          onInput: (bytes) {
            listenerCalled = true;
            return true;
          },
          child: const Text('blocked'),
        ),
      ),
    );

    await tester.sendRawBytes([0x61]);

    expect(listenerCalled, isFalse);
  });

  test('multiple raw input batches each trigger callback', () async {
    tester = await NoctermTester.create(size: const Size(40, 10));

    final received = <List<int>>[];

    await tester.pumpComponent(
      InputListener(
        onInput: (bytes) {
          received.add(List.of(bytes));
          return true;
        },
        child: const Text('hello'),
      ),
    );

    await tester.sendRawBytes([0x61]); // 'a'
    await tester.sendRawBytes([0x62]); // 'b'

    expect(received, hasLength(2));
    expect(received[0], equals([0x61]));
    expect(received[1], equals([0x62]));
  });
}
