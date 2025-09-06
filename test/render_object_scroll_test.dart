import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/keyboard/mouse_event.dart';
import 'package:nocterm/src/rendering/scrollable_render_object.dart';
import 'package:test/test.dart';

void main() {
  group('RenderObject Scrolling', () {
    test('RenderSingleChildViewport handles mouse wheel events', () {
      final controller = ScrollController();
      final renderObject = RenderSingleChildViewport(
        scrollDirection: Axis.vertical,
        controller: controller,
      );

      // Set up scroll metrics (simulate having content to scroll)
      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 20,
      );

      // Initial offset should be 0
      expect(controller.offset, 0.0);

      // Test scroll down
      final wheelDownEvent = MouseEvent(
        x: 10,
        y: 10,
        button: MouseButton.wheelDown,
        pressed: true,
      );
      
      final handled = renderObject.handleMouseWheel(wheelDownEvent);
      expect(handled, true);
      expect(controller.offset, 3.0); // Should scroll 3 lines down

      // Test scroll up
      final wheelUpEvent = MouseEvent(
        x: 10,
        y: 10,
        button: MouseButton.wheelUp,
        pressed: true,
      );
      
      renderObject.handleMouseWheel(wheelUpEvent);
      expect(controller.offset, 0.0); // Should scroll back to 0

      // Cleanup
      renderObject.dispose();
    });

    test('RenderListViewport handles mouse wheel events', () {
      final controller = ScrollController();
      final renderObject = RenderListViewport(
        scrollDirection: Axis.vertical,
        controller: controller,
      );

      // Set up scroll metrics (simulate having content to scroll)
      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 20,
      );

      // Initial offset should be 0
      expect(controller.offset, 0.0);

      // Test scroll down
      final wheelDownEvent = MouseEvent(
        x: 10,
        y: 10,
        button: MouseButton.wheelDown,
        pressed: true,
      );
      
      final handled = renderObject.handleMouseWheel(wheelDownEvent);
      expect(handled, true);
      expect(controller.offset, 3.0); // Should scroll 3 lines down

      // Test scroll up
      final wheelUpEvent = MouseEvent(
        x: 10,
        y: 10,
        button: MouseButton.wheelUp,
        pressed: true,
      );
      
      renderObject.handleMouseWheel(wheelUpEvent);
      expect(controller.offset, 0.0); // Should scroll back to 0

      // Cleanup
      renderObject.dispose();
    });

    test('ScrollableRenderObjectMixin is properly implemented', () {
      // Test that our render objects implement the mixin
      final singleChildViewport = RenderSingleChildViewport(
        scrollDirection: Axis.vertical,
        controller: ScrollController(),
      );
      
      final listViewport = RenderListViewport(
        scrollDirection: Axis.vertical,
        controller: ScrollController(),
      );

      // Check they have the handleMouseWheel method
      final wheelEvent = MouseEvent(
        x: 10,
        y: 10,
        button: MouseButton.wheelDown,
        pressed: true,
      );
      
      // These should work without errors
      singleChildViewport.handleMouseWheel(wheelEvent);
      listViewport.handleMouseWheel(wheelEvent);

      // Cleanup
      singleChildViewport.dispose();
      listViewport.dispose();
    });

    test('Horizontal scrolling works correctly', () {
      final controller = ScrollController();
      final renderObject = RenderSingleChildViewport(
        scrollDirection: Axis.horizontal,
        controller: controller,
      );

      // Set up scroll metrics for horizontal scrolling
      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 20,
      );

      // Test horizontal scrolling with wheel events
      final wheelDownEvent = MouseEvent(
        x: 10,
        y: 10,
        button: MouseButton.wheelDown,
        pressed: true,
      );
      
      renderObject.handleMouseWheel(wheelDownEvent);
      expect(controller.offset, 3.0); // Should scroll horizontally

      // Cleanup
      renderObject.dispose();
    });
  });
}