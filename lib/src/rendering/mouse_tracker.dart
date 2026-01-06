import '../keyboard/mouse_event.dart';
import '../framework/framework.dart';
import 'mouse_hit_test.dart';

/// Signature for mouse enter/exit/hover callbacks.
typedef MouseEventCallback = void Function(MouseEvent event);

/// An annotation that attaches mouse event callbacks to a render object.
class MouseTrackerAnnotation {
  MouseTrackerAnnotation({
    this.onEnter,
    this.onExit,
    this.onHover,
    required this.renderObject,
  });

  /// Called when the mouse enters the annotated region.
  final MouseEventCallback? onEnter;

  /// Called when the mouse exits the annotated region.
  final MouseEventCallback? onExit;

  /// Called when the mouse moves within the annotated region.
  final MouseEventCallback? onHover;

  /// The render object this annotation is attached to.
  final RenderObject renderObject;

  /// Whether this annotation is valid for mouse tracking.
  ///
  /// This is set to false when the render object is detached to prevent
  /// callbacks from being called on disposed objects during mouse event
  /// dispatching.
  bool validForMouseTracker = true;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MouseTrackerAnnotation &&
        other.renderObject == renderObject;
  }

  @override
  int get hashCode => renderObject.hashCode;
}

/// Tracks mouse annotations and dispatches enter/exit/hover events.
class MouseTracker {
  /// The set of annotations currently under the mouse cursor.
  final Set<MouseTrackerAnnotation> _hoveredAnnotations = {};

  /// Update the hovered annotations based on hit test results and dispatch events.
  void updateAnnotations(MouseHitTestResult hitTestResult, MouseEvent event) {
    // Collect all annotations from the hit test result
    final Set<MouseTrackerAnnotation> newAnnotations = {};
    for (final entry in hitTestResult.mouseEntries) {
      if (entry.target is MouseTrackerAnnotationProvider) {
        final annotation =
            (entry.target as MouseTrackerAnnotationProvider).annotation;
        if (annotation != null) {
          newAnnotations.add(annotation);
        }
      }
    }

    // Find annotations that were exited
    final exitedAnnotations = _hoveredAnnotations.difference(newAnnotations);
    for (final annotation in exitedAnnotations) {
      if (annotation.validForMouseTracker) {
        annotation.onExit?.call(event);
      }
    }

    // Find annotations that were entered
    final enteredAnnotations = newAnnotations.difference(_hoveredAnnotations);
    for (final annotation in enteredAnnotations) {
      if (annotation.validForMouseTracker) {
        annotation.onEnter?.call(event);
      }
    }

    // Dispatch hover events to all currently hovered annotations
    for (final annotation in newAnnotations) {
      if (annotation.validForMouseTracker) {
        annotation.onHover?.call(event);
      }
    }

    // Update the set of hovered annotations
    _hoveredAnnotations.clear();
    _hoveredAnnotations.addAll(newAnnotations);
  }

  /// Clear all hovered annotations (e.g., when mouse leaves the terminal).
  void clear(MouseEvent event) {
    for (final annotation in _hoveredAnnotations) {
      annotation.onExit?.call(event);
    }
    _hoveredAnnotations.clear();
  }
}

/// Interface for render objects that provide mouse tracker annotations.
mixin MouseTrackerAnnotationProvider {
  MouseTrackerAnnotation? get annotation;
}
