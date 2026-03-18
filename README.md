[![CI](https://github.com/norbert515/nocterm/actions/workflows/ci.yml/badge.svg)](https://github.com/norbert515/nocterm/actions/workflows/ci.yml)
[![Pub Version](https://img.shields.io/pub/v/nocterm)](https://pub.dev/packages/nocterm)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Website](https://img.shields.io/badge/web-nocterm.dev-blue)](https://nocterm.dev)
[![Documentation](https://img.shields.io/badge/docs-docs.nocterm.dev-blue)](https://docs.nocterm.dev)

<p align="center">
<a href="https://nocterm.dev"><strong>Website</strong></a> |
<a href="https://docs.nocterm.dev"><strong>Docs</strong></a> |
<a href="https://pub.dev/packages/nocterm"><strong>pub.dev</strong></a> |
<a href="#quick-start"><strong>Quick Start</strong></a>
</p>

**If you know Flutter, you know Nocterm.** Build terminal UIs with the same patterns—`StatefulComponent`, `setState()`, `Column`, `Row`, and hot reload.

![Nocterm Demo](doc/assets/demo.gif)


## Installation

```yaml
dependencies:
  nocterm: ^0.6.0
```

## Quick Start

```dart
import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const Counter());
}

class Counter extends StatefulComponent {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.space) {
          setState(() => _count++);
          return true;
        }
        return false;
      },
      child: Center(
        child: Text('Count: $_count'),
      ),
    );
  }
}
```

Run with hot reload:

```bash
dart --enable-vm-service your_app.dart
```

## Testing

Test your TUI components just like Flutter widgets:

```dart
await testNocterm('counter test', (tester) async {
  await tester.pumpComponent(Counter());
  await tester.sendKey(LogicalKey.space);

  expect(tester.terminalState, containsText('Count: 1'));
});
```

## Documentation

See the [full documentation](https://docs.nocterm.dev) for guides on components, state management, testing, and more.

## Community

### Packages

| Package | Description |
|---------|-------------|
| [nocterm_bloc](https://pub.dev/packages/nocterm_bloc) | Bloc state management for Nocterm |
| [nocterm_lints](https://pub.dev/packages/nocterm_lints) | IDE assists — wrap with, swap, move, convert to stateful/stateless |

### Built with Nocterm

| Project | Description |
|---------|-------------|
| [vide_cli](https://github.com/Norbert515/vide_cli) | Multi-agent coding IDE for the terminal |
| [nocterm_3d](https://github.com/Norbert515/nocterm_3d) | Experimental 3D renderer for the terminal |
| [cow](https://github.com/jolexxa/cow) | Local LLM chat client powered by llama.cpp |
| [snake](https://github.com/mrgnhnt96/snake) | Classic Snake for the command line |
| [minesweeper](https://github.com/mrgnhnt96/minesweeper) | Classic Minesweeper for the command line |
| [simutil](https://github.com/dungngminh/simutil) | Quick launch iOS simulators / Android emulators and more |

> Built something with Nocterm? [Open an issue](https://github.com/norbert515/nocterm/issues) to get it listed here!

## Contributing

### Git Hooks

We use [hooksman](https://pub.dev/packages/hooksman) to manage git hooks. To install the hooks, run:

```bash
dart run hooksman
```

## License

MIT
