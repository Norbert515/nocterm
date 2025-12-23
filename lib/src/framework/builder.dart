import 'package:nocterm/src/framework/framework.dart';

typedef ComponentBuilder = Component Function(BuildContext context);

class Builder extends StatelessComponent {
  /// Creates a widget that delegates its build to a callback.
  const Builder({super.key, required this.builder});

  final ComponentBuilder builder;

  @override
  Component build(BuildContext context) => builder(context);
}
