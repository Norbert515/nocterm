part of 'framework.dart';

/// An element that has a build method.
abstract class BuildableElement extends Element {
  BuildableElement(super.component);

  Element? _child;

  bool _debugDoingBuild = false;
  @override
  bool get debugDoingBuild => _debugDoingBuild;

  void _firstBuild() {
    rebuild();
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    _firstBuild();
  }

  @override
  void performRebuild() {
    assert(() {
      _debugDoingBuild = true;
      return true;
    }());

    Component? built;
    try {
      built = build();
    } catch (e, stack) {
      // Handle build errors
      _debugDoingBuild = false;
      built = ErrorComponent(error: e, stackTrace: stack);
      NoctermError.reportError(
        NoctermErrorDetails(
          exception: e,
          stack: stack,
          library: 'nocterm framework',
          context: 'while building $runtimeType',
        ),
      );
    } finally {
      _dirty = false;
      assert(() {
        _debugDoingBuild = false;
        return true;
      }());
    }

    _child = updateChild(_child, built, slot);
  }

  @protected
  Component build();

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_child == child);
    _child = null;
  }
}

/// Component shown when there's an error during build
class ErrorComponent extends StatelessComponent {
  const ErrorComponent({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Component build(BuildContext context) {
    return Text('$error\n$stackTrace');
  }
}
