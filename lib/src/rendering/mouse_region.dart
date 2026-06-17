import '../framework/framework.dart';
import '../framework/terminal_canvas.dart';
import '../rectangle.dart';
import '../size.dart';
import 'mouse_tracker.dart';
import 'mouse_hit_test.dart';

/// Render object for MouseRegion that tracks mouse enter/exit/hover events.
class RenderMouseRegion extends RenderObject
    with
        RenderObjectWithChildMixin<RenderObject>,
        MouseTrackerAnnotationProvider {
  RenderMouseRegion({
    MouseEventCallback? onEnter,
    MouseEventCallback? onExit,
    MouseEventCallback? onHover,
    bool opaque = true,
  })  : _onEnter = onEnter,
        _onExit = onExit,
        _onHover = onHover,
        _opaque = opaque {
    _updateAnnotation();
  }

  MouseEventCallback? _onEnter;
  MouseEventCallback? get onEnter => _onEnter;
  set onEnter(MouseEventCallback? value) {
    if (_onEnter == value) return;
    _onEnter = value;
    _updateAnnotation();
  }

  MouseEventCallback? _onExit;
  MouseEventCallback? get onExit => _onExit;
  set onExit(MouseEventCallback? value) {
    if (_onExit == value) return;
    _onExit = value;
    _updateAnnotation();
  }

  MouseEventCallback? _onHover;
  MouseEventCallback? get onHover => _onHover;
  set onHover(MouseEventCallback? value) {
    if (_onHover == value) return;
    _onHover = value;
    _updateAnnotation();
  }

  bool _opaque;
  bool get opaque => _opaque;
  set opaque(bool value) {
    if (_opaque == value) return;
    _opaque = value;
  }

  MouseTrackerAnnotation? _annotation;

  @override
  MouseTrackerAnnotation? get annotation => _annotation;

  void _updateAnnotation() {
    if (_onEnter != null || _onExit != null || _onHover != null) {
      _annotation = MouseTrackerAnnotation(
        onEnter: _onEnter,
        onExit: _onExit,
        onHover: _onHover,
        renderObject: this,
      );
    } else {
      _annotation = null;
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // Mark annotation as valid when attached
    _annotation?.validForMouseTracker = true;
  }

  @override
  void detach() {
    // It's possible that the renderObject be detached during mouse events
    // dispatching, set the validForMouseTracker false to prevent
    // the callbacks from being called.
    _annotation?.validForMouseTracker = false;
    super.detach();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.constrain(Size.zero);
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      child!.paint(canvas, offset + childParentData.offset);
    }
  }

  @override
  bool hitTest(HitTestResult result, {required Offset position}) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    // Check if position is within bounds
    if (!bounds.contains(position)) {
      return false;
    }

    // Test children first
    bool hitTarget = false;
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      hitTarget = child!.hitTest(result, position: childPosition);
    }

    // Check if we ourselves should be considered a hit
    // If opaque, we hit even if children didn't (to block events from widgets behind us)
    hitTarget = hitTarget || hitTestSelf(position) || _opaque;

    // Add annotation AFTER testing children, only if something was hit
    if (hitTarget && annotation != null && result is MouseHitTestResult) {
      result.addWithPosition(target: this, localPosition: position);
    }

    return hitTarget;
  }

  @override
  bool hitTestSelf(Offset position) {
    // We hit ourselves if we have callbacks
    // Note: The opaque flag is handled by always returning true from hitTest
    // when we're within bounds, which matches Flutter's behavior
    return annotation != null;
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}
