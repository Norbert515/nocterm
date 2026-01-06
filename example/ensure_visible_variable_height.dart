import 'package:nocterm/nocterm.dart';

/// Demonstrates ensureVisible with variable-height items.
///
/// This example shows how to use ScrollController.ensureVisible when items
/// have different heights. You need to track the cumulative offsets manually.
void main() {
  runApp(const VariableHeightListDemo());
}

class VariableHeightListDemo extends StatefulComponent {
  const VariableHeightListDemo({super.key});

  @override
  State<VariableHeightListDemo> createState() => _VariableHeightListDemoState();
}

class _VariableHeightListDemoState extends State<VariableHeightListDemo> {
  int selectedIndex = 0;
  final scrollController = ScrollController();

  // Define items with varying heights
  final items = [
    ('Short item', 1),
    ('Medium item with more text', 2),
    ('Another short', 1),
    ('Tall item:\nLine 1\nLine 2\nLine 3', 4),
    ('Short', 1),
    ('Medium', 2),
    ('Very tall item:\n1\n2\n3\n4\n5', 6),
    ('Short', 1),
    ('Medium item here', 2),
    ('Short', 1),
  ];

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _moveSelection(int newIndex) {
    if (newIndex < 0 || newIndex >= items.length) return;

    setState(() {
      selectedIndex = newIndex;

      // Use index-based API - no need to manually calculate offsets!
      scrollController.ensureIndexVisible(index: selectedIndex);
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.arrowDown) {
          _moveSelection(selectedIndex + 1);
          return true;
        } else if (event.logicalKey == LogicalKey.arrowUp) {
          _moveSelection(selectedIndex - 1);
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
                'Variable Height Items - Use ↑/↓ arrows',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < items.length; i++)
                      Container(
                        decoration: BoxDecoration(
                          color: i == selectedIndex ? Colors.cyan : null,
                          border: const BoxBorder(
                            bottom: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Text(
                          (i == selectedIndex ? '▶ ' : '  ') + items[i].$1,
                          style: TextStyle(
                            color: i == selectedIndex
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                border: const BoxBorder(top: BorderSide(color: Colors.blue)),
              ),
              child: Text(
                'Item $selectedIndex (height: ${items[selectedIndex].$2}) | '
                'Scroll: ${scrollController.offset.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
