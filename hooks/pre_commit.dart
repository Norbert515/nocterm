import 'package:hooksman/hooksman.dart';

Hook main() {
  return PreCommitHook(
    tasks: [
      ReRegisterHooks(),
      ShellTask(
        include: [Glob('**/*.dart')],
        exclude: [Glob('third_party/**')],
        commands: (files) => ['dart format ${files.join(' ')}'],
      ),
    ],
  );
}
