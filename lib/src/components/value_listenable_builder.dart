import 'package:nocterm/src/framework/framework.dart';
import 'package:nocterm/src/framework/value_listenable.dart';

typedef ValueComponentBuilder<T> =
    Component Function(BuildContext context, T value, Component? child);

class ValueListenableBuilder<T> extends StatefulComponent {
  const ValueListenableBuilder({
    super.key,
    required this.valueListenable,
    required this.builder,
    this.child,
  });

  final ValueListenable<T> valueListenable;

  final ValueComponentBuilder<T> builder;

  final Component? child;

  @override
  State<StatefulComponent> createState() => _ValueListenableBuilderState<T>();
}

class _ValueListenableBuilderState<T> extends State<ValueListenableBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = component.valueListenable.value;
    component.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateComponent(ValueListenableBuilder<T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.valueListenable != component.valueListenable) {
      oldComponent.valueListenable.removeListener(_valueChanged);
      value = component.valueListenable.value;
      component.valueListenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    component.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {
      value = component.valueListenable.value;
    });
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, value, component.child);
  }
}
