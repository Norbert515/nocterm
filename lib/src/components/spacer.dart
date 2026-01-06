import '../framework/framework.dart';
import 'basic.dart';

class Spacer extends StatelessComponent {
  const Spacer({super.key, this.flex = 1});

  final int flex;

  @override
  Component build(BuildContext context) {
    return Expanded(flex: flex, child: const SizedBox());
  }
}
