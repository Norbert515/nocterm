import '../framework/framework.dart';

class Builder extends StatelessComponent {
  /// Creates a widget that delegates its build to a callback.
  const Builder({super.key, required this.builder});

  final ComponentBuilder builder;

  @override
  Component build(BuildContext context) => builder(context);
}
