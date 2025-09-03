import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:nocterm/src/components/basic.dart';
import 'package:nocterm/src/rectangle.dart';
import 'package:nocterm/src/size.dart';

import 'terminal_canvas.dart';

part 'component.dart';
part 'element.dart';
part 'build_context.dart';
part 'build_owner.dart';
part 'render_object.dart';
part 'stateless_component.dart';
part 'stateful_component.dart';
part 'buildable_element.dart';
part 'keys.dart';
part 'binding.dart';

typedef ComponentBuilder = Component Function(BuildContext context);
typedef StateSetter = void Function(VoidCallback fn);
typedef VoidCallback = void Function();
typedef ElementVisitor = void Function(Element element);

/// Base class for all TUI components (similar to Flutter's Widget)
@immutable
abstract class Component {
  const Component({this.key});

  final Key? key;

  @protected
  Element createElement();

  static bool canUpdate(Component oldComponent, Component newComponent) {
    return oldComponent.runtimeType == newComponent.runtimeType && oldComponent.key == newComponent.key;
  }
}

abstract class SingleChildRenderObjectComponent extends RenderObjectComponent {
  const SingleChildRenderObjectComponent({super.key, this.child});

  final Component? child;

  @override
  SingleChildRenderObjectElement createElement() => SingleChildRenderObjectElement(this);
}

abstract class MultiChildRenderObjectComponent extends RenderObjectComponent {
  const MultiChildRenderObjectComponent({super.key, this.children = const []});

  final List<Component> children;

  @override
  MultiChildRenderObjectElement createElement() => MultiChildRenderObjectElement(this);
}
