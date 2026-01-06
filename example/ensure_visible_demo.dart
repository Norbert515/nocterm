import 'package:nocterm/nocterm.dart';

/// Demonstrates using ScrollController.ensureVisible for keyboard navigation.
///
/// This example shows a selectable list where arrow keys navigate through items,
/// and the scroll position automatically adjusts to keep the selected item visible.
void main() {
  runApp(const SelectableListDemo());
}

class SelectableListDemo extends StatefulComponent {
  const SelectableListDemo({super.key});

  @override
  State<SelectableListDemo> createState() => _SelectableListDemoState();
}

class _SelectableListDemoState extends State<SelectableListDemo> {
  int selectedIndex = 0;
  final scrollController = ScrollController();
  final itemCount = 30;

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _moveSelection(int delta) {
    setState(() {
      final newIndex = (selectedIndex + delta).clamp(0, itemCount - 1);
      if (newIndex != selectedIndex) {
        selectedIndex = newIndex;

        // Automatically scroll to keep the selected item visible using index-based API
        scrollController.ensureIndexVisible(index: selectedIndex);
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.arrowDown) {
          _moveSelection(1);
          return true;
        } else if (event.logicalKey == LogicalKey.arrowUp) {
          _moveSelection(-1);
          return true;
        } else if (event.logicalKey == LogicalKey.home) {
          setState(() {
            selectedIndex = 0;
            scrollController.scrollToStart();
          });
          return true;
        } else if (event.logicalKey == LogicalKey.end) {
          setState(() {
            selectedIndex = itemCount - 1;
            scrollController.scrollToEnd();
          });
          return true;
        } else if (event.logicalKey == LogicalKey.pageDown) {
          _moveSelection(10);
          return true;
        } else if (event.logicalKey == LogicalKey.pageUp) {
          _moveSelection(-10);
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(border: BoxBorder.all(color: Colors.blue)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Selectable List Demo - Use ↑/↓ arrows, PgUp/PgDn, Home/End',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedIndex;
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyan : null,
                    ),
                    child: Text(
                      isSelected ? '▶ Item $index (selected)' : '  Item $index',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                border: const BoxBorder(top: BorderSide(color: Colors.blue)),
              ),
              child: Text(
                'Selected: $selectedIndex/$itemCount | Scroll: ${scrollController.offset.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
