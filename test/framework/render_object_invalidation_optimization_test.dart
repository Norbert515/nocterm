import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/components/decorated_box.dart';
import 'package:nocterm/src/components/render_text.dart';
import 'package:test/test.dart';

void main() {
  group('render object invalidation optimization', () {
    test('RenderText downgrades same-footprint text changes to paint', () {
      final render = RenderText(text: '1');
      render.layout(const BoxConstraints(maxWidth: 10, maxHeight: 5));

      render.text = '2';

      expect(render.needsLayout, isFalse);
      expect(render.needsPaint, isTrue);
      expect(render.selectableLayout?.lines, ['2']);
    });

    test('RenderText relayouts when text footprint changes', () {
      final render = RenderText(text: '9');
      render.layout(const BoxConstraints(maxWidth: 10, maxHeight: 5));

      render.text = '10';

      expect(render.needsLayout, isTrue);
      expect(render.needsPaint, isTrue);
    });

    test('RenderText respects parent-determined size for text changes', () {
      final render = RenderText(text: '9');
      render.layout(BoxConstraints.tight(const Size(8, 1)));

      render.text = '10';

      expect(render.needsLayout, isFalse);
      expect(render.needsPaint, isTrue);
      expect(render.size, const Size(8, 1));
      expect(render.selectableLayout?.lines, ['10']);
    });

    test('RenderParagraph downgrades style-only span changes to paint', () {
      final render = RenderParagraph(
        text: const TextSpan(
          text: 'status',
          style: TextStyle(color: Colors.red),
        ),
      );
      render.layout(const BoxConstraints(maxWidth: 20, maxHeight: 5));

      render.text = const TextSpan(
        text: 'status',
        style: TextStyle(color: Colors.green),
      );

      expect(render.needsLayout, isFalse);
      expect(render.needsPaint, isTrue);
      expect(render.selectableLayout?.lines, ['status']);
    });

    test('RenderDecoratedBox downgrades paint-only decoration changes', () {
      final render = RenderDecoratedBox(
        decoration: const BoxDecoration(color: Colors.red),
      );
      render.layout(const BoxConstraints(maxWidth: 10, maxHeight: 5));

      render.decoration = const BoxDecoration(color: Colors.green);

      expect(render.needsLayout, isFalse);
      expect(render.needsPaint, isTrue);
    });

    test('RenderDecoratedBox relayouts when border inset changes', () {
      final render = RenderDecoratedBox(
        decoration: const BoxDecoration(color: Colors.red),
      );
      render.layout(const BoxConstraints(maxWidth: 10, maxHeight: 5));

      render.decoration = const BoxDecoration(
        color: Colors.red,
        border: BoxBorder(
          top: BorderSide(color: Colors.green),
        ),
      );

      expect(render.needsLayout, isTrue);
      expect(render.needsPaint, isTrue);
    });
  });
}
