import 'package:nocterm/nocterm.dart';

/// A callback type for when a tab selection changes.
typedef TabChangedCallback = void Function(int index);

/// A horizontal tab bar component that renders a row of selectable tab labels
/// with an active indicator underline.
///
/// The selected tab is displayed with bold text and a colored underline,
/// while unselected tabs are displayed with dimmed text.
///
/// Supports both keyboard navigation (left/right arrows, number keys, home and end) and
/// mouse click selection via [GestureDetector].
///
/// Example:
/// ```dart
/// TabComponent(
///   tabs: ['Tab 1', 'Tab 2', 'Tab 3', 'Tab 4'],
///   selectedIndex: _selectedIndex ?? 0,
///   onChanged: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
class TabComponent extends StatefulComponent {
  const TabComponent({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onChanged,
    this.indicatorColor,
    this.selectedLabelColor,
    this.unselectedLabelColor,
  });

  /// The list of tab label strings to display.
  final List<String> tabs;

  /// The index of the currently selected tab.
  final int selectedIndex;

  /// Called when the user selects a different tab.
  final TabChangedCallback? onChanged;

  /// The color of the indicator underline below the selected tab.
  ///
  /// If null, defaults to the theme's [TuiThemeData.primary] color.
  final Color? indicatorColor;

  /// The text color for the selected tab label.
  ///
  /// If null, defaults to the theme's [TuiThemeData.onSurface] color.
  final Color? selectedLabelColor;

  /// The text color for unselected tab labels.
  ///
  /// If null, defaults to the theme's [TuiThemeData.outlineVariant] color.
  final Color? unselectedLabelColor;

  @override
  State<TabComponent> createState() => _TabComponentState();
}

class _TabComponentState extends State<TabComponent> {
  void _selectTab(int index) {
    if (index != component.selectedIndex &&
        index >= 0 &&
        index < component.tabs.length) {
      component.onChanged?.call(index);
    }
  }

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final indicatorColor = component.indicatorColor ?? theme.primary;
    final selectedColor = component.selectedLabelColor ?? theme.onSurface;
    final unselectedColor =
        component.unselectedLabelColor ?? theme.outlineVariant;
    final dividerColor = theme.outlineVariant;

    final labelChildren = <Component>[];
    for (int i = 0; i < component.tabs.length; i++) {
      final isSelected = i == component.selectedIndex;
      final label = component.tabs[i];
      final index = i;

      labelChildren.add(
        GestureDetector(
          onTap: () => _selectTab(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    // Build indicator/divider segments for the bottom row.
    // Each tab segment matches the label width (label.length + 2 for padding).
    // The selected tab uses '━' in indicatorColor, the rest uses '─' in dividerColor.
    final indicatorChildren = <Component>[];
    for (int i = 0; i < component.tabs.length; i++) {
      final isSelected = i == component.selectedIndex;
      final segmentWidth = component.tabs[i].length + 2; // +2 for h-padding

      indicatorChildren.add(
        SizedBox(
          width: segmentWidth.toDouble(),
          height: 1,
          child: Text(
            isSelected ? '━' * segmentWidth : '─' * segmentWidth,
            style: TextStyle(
              color: isSelected ? indicatorColor : dividerColor,
            ),
          ),
        ),
      );
    }

    indicatorChildren.add(
      Expanded(
        child: Divider(
          color: dividerColor,
          thickness: 1,
        ),
      ),
    );

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.arrowLeft) {
          _selectTab(component.selectedIndex - 1);
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowRight) {
          _selectTab(component.selectedIndex + 1);
          return true;
        }

        if (event.logicalKey == LogicalKey.home) {
          _selectTab(0);
          return true;
        }

        if (event.logicalKey == LogicalKey.end) {
          _selectTab(component.tabs.length - 1);
          return true;
        }

        // Number keys 1-9 to select tabs directly
        if (event.character != null) {
          final num = int.tryParse(event.character!);
          if (num != null && num >= 1 && num <= component.tabs.length) {
            _selectTab(num - 1);
            return true;
          }
        }
        return false;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: labelChildren),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: indicatorChildren,
          ),
        ],
      ),
    );
  }
}
