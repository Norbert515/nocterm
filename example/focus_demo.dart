import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const FocusDemo());
}

/// Demo application showing focus handling with nested components
class FocusDemo extends StatefulComponent {
  const FocusDemo({super.key});

  @override
  State<FocusDemo> createState() => _FocusDemoState();
}

enum FocusArea { sidebar, main, footer }

class _FocusDemoState extends State<FocusDemo> {
  FocusArea focusedArea = FocusArea.sidebar;
  int sidebarIndex = 0;
  int mainTabIndex = 0;
  String lastKeyPressed = 'None';
  final List<String> sidebarItems = [
    'Dashboard',
    'Settings',
    'Profile',
    'Help',
    'About',
  ];
  final List<String> mainTabs = ['Overview', 'Details', 'Analytics'];

  void _updateLastKey(String key) {
    setState(() {
      lastKeyPressed = key;
    });
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        Text(lastKeyPressed),
        Text(sidebarIndex.toString()),
        Text(focusedArea.toString()),
        // Header
        Container(
          height: 3,
          decoration: BoxDecoration(border: BoxBorder.all(color: Colors.cyan)),
          child: Center(
            child: Text(
              'Focus Demo - Use Arrow Keys to Navigate, Tab to Switch Areas $lastKeyPressed',
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Text('hi'),

        // Main content area
        Expanded(
          child: Row(
            children: [
              // Sidebar
              Focusable(
                focused: focusedArea == FocusArea.sidebar,
                onKeyEvent: (event) {
                  if (event.logicalKey == LogicalKey.arrowUp) {
                    _updateLastKey('Arrow Up');
                    setState(() {
                      if (sidebarIndex > 0) sidebarIndex--;
                    });
                    return true;
                  } else if (event.logicalKey == LogicalKey.arrowDown) {
                    _updateLastKey('Arrow Down');
                    setState(() {
                      if (sidebarIndex < sidebarItems.length - 1) {
                        sidebarIndex++;
                      }
                    });
                    return true;
                  } else if (event.logicalKey == LogicalKey.arrowRight ||
                      event.logicalKey == LogicalKey.tab) {
                    _updateLastKey(
                      event.logicalKey == LogicalKey.tab
                          ? 'Tab'
                          : 'Arrow Right',
                    );
                    setState(() {
                      focusedArea = FocusArea.main;
                    });
                    return true;
                  }
                  return false;
                },
                child: Container(
                  width: 20,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(
                      color: focusedArea == FocusArea.sidebar
                          ? Colors.green
                          : Colors.gray,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1),
                        child: Text(
                          'Sidebar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: focusedArea == FocusArea.sidebar
                                ? Colors.green
                                : Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < sidebarItems.length; i++)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: Text(
                                  ' ${i == sidebarIndex && focusedArea == FocusArea.sidebar ? '>' : ' '} ${sidebarItems[i]}',
                                  style: TextStyle(
                                    color:
                                        i == sidebarIndex &&
                                            focusedArea == FocusArea.sidebar
                                        ? Colors.white
                                        : Colors.gray,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Focusable(
                  focused: focusedArea == FocusArea.main,
                  onKeyEvent: (event) {
                    if (event.logicalKey == LogicalKey.arrowLeft) {
                      _updateLastKey('Arrow Left');
                      setState(() {
                        if (mainTabIndex > 0) {
                          mainTabIndex--;
                        } else {
                          focusedArea = FocusArea.sidebar;
                        }
                      });
                      return true;
                    } else if (event.logicalKey == LogicalKey.arrowRight) {
                      _updateLastKey('Arrow Right');
                      setState(() {
                        if (mainTabIndex < mainTabs.length - 1) {
                          mainTabIndex++;
                        }
                      });
                      return true;
                    } else if (event.logicalKey == LogicalKey.arrowDown) {
                      _updateLastKey('Arrow Down');
                      setState(() {
                        focusedArea = FocusArea.footer;
                      });
                      return true;
                    } else if (event.logicalKey == LogicalKey.tab) {
                      _updateLastKey('Tab');
                      setState(() {
                        focusedArea = FocusArea.footer;
                      });
                      return true;
                    } else if (event.logicalKey == LogicalKey.tab &&
                        event.isShiftPressed) {
                      _updateLastKey('Shift+Tab');
                      setState(() {
                        focusedArea = FocusArea.sidebar;
                      });
                      return true;
                    }
                    return false;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(
                        color: focusedArea == FocusArea.main
                            ? Colors.green
                            : Colors.gray,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Tab bar
                        Container(
                          height: 3,
                          padding: const EdgeInsets.all(1),
                          child: Row(
                            children: [
                              for (int i = 0; i < mainTabs.length; i++) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration:
                                      i == mainTabIndex &&
                                          focusedArea == FocusArea.main
                                      ? BoxDecoration(
                                          color: Colors.blue,
                                          border: BoxBorder.all(
                                            color: Colors.cyan,
                                          ),
                                        )
                                      : BoxDecoration(
                                          border: BoxBorder.all(
                                            color: Colors.gray,
                                          ),
                                        ),
                                  child: Text(
                                    mainTabs[i],
                                    style: TextStyle(
                                      color:
                                          i == mainTabIndex &&
                                              focusedArea == FocusArea.main
                                          ? Colors.white
                                          : Colors.gray,
                                      fontWeight:
                                          i == mainTabIndex &&
                                              focusedArea == FocusArea.main
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (i < mainTabs.length - 1)
                                  const SizedBox(width: 1),
                              ],
                            ],
                          ),
                        ),

                        // Content
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Main Content Area',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: focusedArea == FocusArea.main
                                        ? Colors.green
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text('Selected Tab: ${mainTabs[mainTabIndex]}'),
                                Text(
                                  'Selected Sidebar: ${sidebarItems[sidebarIndex]}',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Last Key Pressed: $lastKeyPressed',
                                  style: TextStyle(color: Colors.yellow),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Controls:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('• Arrow Keys: Navigate within area'),
                                Text('• Tab: Move to next area'),
                                Text('• Shift+Tab: Move to previous area'),
                                Text('• Escape or Ctrl+C: Exit'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Footer
        Focusable(
          focused: focusedArea == FocusArea.footer,
          onKeyEvent: (event) {
            if (event.logicalKey == LogicalKey.arrowUp) {
              _updateLastKey('Arrow Up');
              setState(() {
                focusedArea = FocusArea.main;
              });
              return true;
            } else if (event.logicalKey == LogicalKey.tab) {
              _updateLastKey('Tab');
              setState(() {
                focusedArea = FocusArea.sidebar;
              });
              return true;
            } else if (event.logicalKey == LogicalKey.tab &&
                event.isShiftPressed) {
              _updateLastKey('Shift+Tab');
              setState(() {
                focusedArea = FocusArea.main;
              });
              return true;
            } else if (event.logicalKey == LogicalKey.keyQ) {
              _updateLastKey('Q - Exiting');
              // Let Q bubble up to exit
              return false;
            }
            // Log any other key
            _updateLastKey(event.logicalKey.toString());
            return true;
          },
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              border: BoxBorder.all(
                color: focusedArea == FocusArea.footer
                    ? Colors.green
                    : Colors.gray,
              ),
              color: focusedArea == FocusArea.footer
                  ? Color.fromRGB(0, 0, 64)
                  : null,
            ),
            child: Center(
              child: Text(
                focusedArea == FocusArea.footer
                    ? 'Footer (Focused) - Press Q to quit, Arrow Up to go back'
                    : 'Footer - Tab here to focus',
                style: TextStyle(
                  color: focusedArea == FocusArea.footer
                      ? Colors.white
                      : Colors.gray,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WrappedText extends StatelessComponent {
  const WrappedText({required this.text});

  final String text;

  @override
  Component build(BuildContext context) {
    return Text(text);
  }
}
