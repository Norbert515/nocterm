import 'dart:io';
import 'package:nocterm/nocterm.dart';

// Debug log file
final _debugLog = File('mouse_debug.log');

void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  _debugLog.writeAsStringSync('[$timestamp] $message\n', mode: FileMode.append);
}

void main() {
  // Clear previous debug log
  if (_debugLog.existsSync()) {
    _debugLog.deleteSync();
  }
  _log('=== Mouse Demo Started ===');

  runApp(const MouseDemo());
}

class MouseDemo extends StatefulComponent {
  const MouseDemo({super.key});

  @override
  State<MouseDemo> createState() => _MouseDemoState();
}

class _MouseDemoState extends State<MouseDemo> {
  int? _hoveredListItem;
  int? _selectedListItem;

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        Container(width: 100, height: 30, color: Color.fromRGB(100, 100, 100)),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: ListView(
            children: List.generate(10, (index) {
              final isHovered = _hoveredListItem == index;
              final isSelected = _selectedListItem == index;
              return Container(
                child: Column(
                  children: [
                    MouseRegion(
                      onEnter: (event) {
                        _log('ListView item $index: onEnter');
                        setState(() {
                          _hoveredListItem = index;
                        });
                      },
                      onExit: (event) {
                        _log('ListView item $index: onExit');
                        setState(() {
                          _hoveredListItem = null;
                        });
                      },
                      child: GestureDetector(
                        onTap: () {
                          shutdownApp();
                          _log('ListView item $index: onTap');
                          setState(() {
                            _selectedListItem = index;
                          });
                        },
                        child: Container(
                          //padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                          decoration: BoxDecoration(
                            //border: BoxBorder.all(),
                            color: Colors.red,
                          ),
                          child: Text(
                            isSelected
                                ? '▶ Item $index (Selected)'
                                : isHovered
                                ? '→ Item $index (Hovered)'
                                : '  Item $index',
                            style: TextStyle(
                              fontWeight: isSelected || isHovered
                                  ? FontWeight.bold
                                  : null,
                              color: isSelected
                                  ? const Color(0xFF00FF00)
                                  : isHovered
                                  ? const Color(0xFFFFFF00)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
