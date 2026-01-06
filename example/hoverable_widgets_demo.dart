import 'dart:io';
import 'package:nocterm/nocterm.dart';

final _debugLog = File('hoverable_widgets_demo_debug.log');

void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  _debugLog.writeAsStringSync('[$timestamp] $message\n', mode: FileMode.append);
}

void main() {
  if (_debugLog.existsSync()) {
    _debugLog.deleteSync();
  }

  runApp(const HoverableWidgetsDemo());
}

class HoverableWidgetsDemo extends StatefulComponent {
  const HoverableWidgetsDemo({super.key});

  @override
  State<HoverableWidgetsDemo> createState() => _HoverableWidgetsDemoState();
}

class _HoverableWidgetsDemoState extends State<HoverableWidgetsDemo> {
  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: BoxBorder.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0066CC),
              border: BoxBorder(bottom: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              '🎨 HOVERABLE WIDGETS SHOWCASE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),

          // Main content area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Buttons
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: BoxBorder(right: BorderSide()),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '━━━ BUTTONS ━━━',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 1),
                        const HoverButton(
                          label: 'Primary Button',
                          style: ButtonStyle.primary,
                        ),
                        const SizedBox(height: 1),
                        const HoverButton(
                          label: 'Success Button',
                          style: ButtonStyle.success,
                        ),
                        const SizedBox(height: 1),
                        const HoverButton(
                          label: 'Warning Button',
                          style: ButtonStyle.warning,
                        ),
                        const SizedBox(height: 1),
                        const HoverButton(
                          label: 'Danger Button',
                          style: ButtonStyle.danger,
                        ),
                        const SizedBox(height: 1),
                        const HoverButton(
                          label: 'Outlined Button',
                          style: ButtonStyle.outlined,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '━━━ CARDS ━━━',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 1),
                        const HoverCard(
                          title: 'Interactive Card',
                          description: 'Hover to see effect',
                        ),
                        const SizedBox(height: 1),
                        const HoverCard(
                          title: 'Settings Card',
                          description: 'Click to configure',
                          icon: '⚙',
                        ),
                      ],
                    ),
                  ),
                ),

                // Right column - Lists and toggles
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '━━━ MENU LIST ━━━',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 1),
                        const HoverMenuList(),
                        const SizedBox(height: 2),
                        const Text(
                          '━━━ TOGGLES ━━━',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 1),
                        const HoverToggle(label: 'Dark Mode'),
                        const SizedBox(height: 1),
                        const HoverToggle(label: 'Notifications'),
                        const SizedBox(height: 1),
                        const HoverToggle(label: 'Sound Effects'),
                        const SizedBox(height: 2),
                        const Text(
                          '━━━ TABS ━━━',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 1),
                        const HoverTabBar(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer with status
          Container(
            decoration: const BoxDecoration(
              border: BoxBorder(top: BorderSide()),
              color: Color(0xFF222222),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: const Text(
              '💡 Hover over any widget to see interactive effects',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
        ],
      ),
    );
  }
}

// Button Styles Enum
enum ButtonStyle { primary, success, warning, danger, outlined }

// Hoverable Button Widget
class HoverButton extends StatefulComponent {
  final String label;
  final ButtonStyle style;

  const HoverButton({
    super.key,
    required this.label,
    this.style = ButtonStyle.primary,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  Color _getBaseColor() {
    return switch (component.style) {
      ButtonStyle.primary => const Color(0xFF0066CC),
      ButtonStyle.success => const Color(0xFF00AA00),
      ButtonStyle.warning => const Color(0xFFFFAA00),
      ButtonStyle.danger => const Color(0xFFCC0000),
      ButtonStyle.outlined => const Color(0xFF666666),
    };
  }

  Color _getHoverColor() {
    return switch (component.style) {
      ButtonStyle.primary => const Color(0xFF0088FF),
      ButtonStyle.success => const Color(0xFF00DD00),
      ButtonStyle.warning => const Color(0xFFFFCC00),
      ButtonStyle.danger => const Color(0xFFFF0000),
      ButtonStyle.outlined => const Color(0xFF888888),
    };
  }

  Color _getPressedColor() {
    return switch (component.style) {
      ButtonStyle.primary => const Color(0xFF004488),
      ButtonStyle.success => const Color(0xFF008800),
      ButtonStyle.warning => const Color(0xFFDD8800),
      ButtonStyle.danger => const Color(0xFF880000),
      ButtonStyle.outlined => const Color(0xFF444444),
    };
  }

  @override
  Component build(BuildContext context) {
    final color = _isPressed
        ? _getPressedColor()
        : _isHovering
        ? _getHoverColor()
        : _getBaseColor();

    final prefix = _isPressed
        ? '▼'
        : _isHovering
        ? '▶'
        : ' ';

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovering = true;
        });
        _log('Button "${component.label}" - Hover ENTER');
      },
      onExit: (event) {
        setState(() {
          _isHovering = false;
          _isPressed = false;
        });
        _log('Button "${component.label}" - Hover EXIT');
      },
      child: GestureDetector(
        onTapDown: (details) {
          setState(() {
            _isPressed = true;
          });
          _log('Button "${component.label}" - TAP DOWN');
        },
        onTapUp: (details) {
          setState(() {
            _isPressed = false;
          });
          _log('Button "${component.label}" - TAP UP');
        },
        onTap: () {
          _log('Button "${component.label}" - CLICKED');
        },
        child: Container(
          decoration: BoxDecoration(
            color: component.style == ButtonStyle.outlined ? null : color,
            border: component.style == ButtonStyle.outlined
                ? BoxBorder.all(color: color)
                : BoxBorder.all(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Text(
            '$prefix ${component.label}',
            style: TextStyle(
              color: component.style == ButtonStyle.outlined
                  ? color
                  : const Color(0xFFFFFFFF),
              fontWeight: _isHovering ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }
}

// Hoverable Card Widget
class HoverCard extends StatefulComponent {
  final String title;
  final String description;
  final String? icon;

  const HoverCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;

  @override
  Component build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovering = true;
        });
        _log('Card "${component.title}" - Hover ENTER');
      },
      onExit: (event) {
        setState(() {
          _isHovering = false;
        });
        _log('Card "${component.title}" - Hover EXIT');
      },
      child: GestureDetector(
        onTap: () {
          _log('Card "${component.title}" - CLICKED');
        },
        child: Container(
          decoration: BoxDecoration(
            border: BoxBorder.all(
              color: _isHovering
                  ? const Color(0xFF00FFFF)
                  : const Color(0xFF444444),
            ),
            color: _isHovering ? const Color(0xFF333333) : null,
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              if (component.icon != null) ...[
                Text(
                  component.icon!,
                  style: TextStyle(
                    color: _isHovering ? const Color(0xFF00FFFF) : null,
                  ),
                ),
                const SizedBox(width: 1),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isHovering ? const Color(0xFF00FFFF) : null,
                      ),
                    ),
                    Text(
                      component.description,
                      style: const TextStyle(color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              if (_isHovering)
                const Text(
                  '→',
                  style: TextStyle(
                    color: Color(0xFF00FFFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hoverable Menu List
class HoverMenuList extends StatefulComponent {
  const HoverMenuList({super.key});

  @override
  State<HoverMenuList> createState() => _HoverMenuListState();
}

class _HoverMenuListState extends State<HoverMenuList> {
  int? _hoveredIndex;
  int? _selectedIndex;

  final List<MenuItem> _items = const [
    MenuItem(icon: '📁', label: 'Files'),
    MenuItem(icon: '🔍', label: 'Search'),
    MenuItem(icon: '⚙', label: 'Settings'),
    MenuItem(icon: '❓', label: 'Help'),
  ];

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: BoxBorder.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isHovered = _hoveredIndex == index;
          final isSelected = _selectedIndex == index;

          return MouseRegion(
            onEnter: (event) {
              setState(() {
                _hoveredIndex = index;
              });
              _log('Menu item "${item.label}" - Hover ENTER');
            },
            onExit: (event) {
              setState(() {
                _hoveredIndex = null;
              });
              _log('Menu item "${item.label}" - Hover EXIT');
            },
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                _log('Menu item "${item.label}" - SELECTED');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0066CC)
                      : isHovered
                      ? const Color(0xFF444444)
                      : null,
                  border: index < _items.length - 1
                      ? const BoxBorder(bottom: BorderSide())
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Row(
                  children: [
                    Text(
                      item.icon,
                      style: TextStyle(
                        color: isSelected || isHovered
                            ? const Color(0xFFFFFFFF)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected || isHovered
                              ? const Color(0xFFFFFFFF)
                              : null,
                          fontWeight: isSelected || isHovered
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Text(
                        '✓',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isHovered)
                      const Text(
                        '→',
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MenuItem {
  final String icon;
  final String label;

  const MenuItem({required this.icon, required this.label});
}

// Hoverable Toggle Switch
class HoverToggle extends StatefulComponent {
  final String label;

  const HoverToggle({super.key, required this.label});

  @override
  State<HoverToggle> createState() => _HoverToggleState();
}

class _HoverToggleState extends State<HoverToggle> {
  bool _isHovering = false;
  bool _isEnabled = false;

  @override
  Component build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovering = true;
        });
        _log('Toggle "${component.label}" - Hover ENTER');
      },
      onExit: (event) {
        setState(() {
          _isHovering = false;
        });
        _log('Toggle "${component.label}" - Hover EXIT');
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isEnabled = !_isEnabled;
          });
          _log(
            'Toggle "${component.label}" - TOGGLED to ${_isEnabled ? "ON" : "OFF"}',
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: _isHovering
                ? BoxBorder.all(color: const Color(0xFF00FFFF))
                : null,
            color: _isHovering ? const Color(0xFF222222) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _isEnabled
                      ? const Color(0xFF00AA00)
                      : const Color(0xFF444444),
                  border: BoxBorder.all(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  _isEnabled ? '●' : '○',
                  style: TextStyle(
                    color: _isEnabled
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF888888),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  component.label,
                  style: TextStyle(
                    color: _isHovering ? const Color(0xFF00FFFF) : null,
                    fontWeight: _isHovering ? FontWeight.bold : null,
                  ),
                ),
              ),
              Text(
                _isEnabled ? 'ON ' : 'OFF',
                style: TextStyle(
                  color: _isEnabled
                      ? const Color(0xFF00AA00)
                      : const Color(0xFF888888),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hoverable Tab Bar
class HoverTabBar extends StatefulComponent {
  const HoverTabBar({super.key});

  @override
  State<HoverTabBar> createState() => _HoverTabBarState();
}

class _HoverTabBarState extends State<HoverTabBar> {
  int? _hoveredTab;
  int _selectedTab = 0;

  final List<String> _tabs = const ['Home', 'Profile', 'Settings', 'About'];

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab headers
        Container(
          decoration: BoxDecoration(border: BoxBorder.all()),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isHovered = _hoveredTab == index;
              final isSelected = _selectedTab == index;

              return Expanded(
                child: MouseRegion(
                  onEnter: (event) {
                    setState(() {
                      _hoveredTab = index;
                    });
                    _log('Tab "${_tabs[index]}" - Hover ENTER');
                  },
                  onExit: (event) {
                    setState(() {
                      _hoveredTab = null;
                    });
                    _log('Tab "${_tabs[index]}" - Hover EXIT');
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = index;
                      });
                      _log('Tab "${_tabs[index]}" - SELECTED');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0066CC)
                            : isHovered
                            ? const Color(0xFF444444)
                            : null,
                        border: index < _tabs.length - 1
                            ? const BoxBorder(right: BorderSide())
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          color: isSelected || isHovered
                              ? const Color(0xFFFFFFFF)
                              : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Tab content
        Container(
          decoration: BoxDecoration(border: BoxBorder.all()),
          padding: const EdgeInsets.all(2),
          child: Text(
            'Content for ${_tabs[_selectedTab]} tab',
            style: const TextStyle(color: Color(0xFF888888)),
          ),
        ),
      ],
    );
  }
}
