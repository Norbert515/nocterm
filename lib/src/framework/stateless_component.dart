part of 'framework.dart';

/// A component that does not require mutable state.
abstract class StatelessComponent extends Component {
  const StatelessComponent({super.key});

  @override
  StatelessElement createElement() => StatelessElement(this);

  /// Describes the part of the user interface represented by this component.
  @protected
  Component build(BuildContext context);
}

/// Element for StatelessComponent
class StatelessElement extends BuildableElement {
  StatelessElement(StatelessComponent super.component);

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    // Trigger a rebuild when the component is updated to ensure
    // child components receive state updates from parent
    rebuild();
  }

  @override
  StatelessComponent get component => super.component as StatelessComponent;

  @override
  Component build() => component.build(this);
}
