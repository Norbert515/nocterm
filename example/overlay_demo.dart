import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const OverlayDemo());
}

class OverlayDemo extends StatefulComponent {
  const OverlayDemo({super.key});

  @override
  State<OverlayDemo> createState() => _OverlayDemoState();
}

class _OverlayDemoState extends State<OverlayDemo> {
  OverlayEntry? _overlayEntry;
  late OverlayState _overlayState;

  @override
  void initState() {
    super.initState();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 10,
        top: 5,
        child: Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Colors.cyan),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Overlay Window'),
                const SizedBox(height: 1),
                Text(
                  'Terminal BG shows through!',
                  style: TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 1),
                Text(
                  'Press ESC to close',
                  style: TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _overlayState.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Component build(BuildContext context) {
    return Overlay(
      initialEntries: [
          OverlayEntry(
            builder: (context) {
              // Store the overlay state for later use
              Future.microtask(() {
                _overlayState = Overlay.of(context);
              });

              return KeyboardListener(
                onKeyEvent: (event) {
                  if (event == LogicalKey.escape) {
                    if (_overlayEntry != null) {
                      _hideOverlay();
                    } else {
                      shutdownApp();
                    }
                    return true;
                  } else if (event == LogicalKey.keyO) {
                    if (_overlayEntry == null) {
                      _showOverlay();
                    }
                    return true;
                  }
                  return false;
                },
                child: Container(
                  color: null, // Terminal default background
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Overlay Demo',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('This demo shows overlays with terminal default background'),
                        const SizedBox(height: 1),
                        Text(
                          'The overlay won\'t have a gray background - it uses terminal\'s default!',
                          style: TextStyle(color: Colors.green),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.yellow),
                          ),
                          child: Column(
                            children: [
                              Text('Press "O" to show overlay', style: TextStyle(color: Colors.yellow)),
                              Text('Press ESC to close overlay/exit', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
  }
}