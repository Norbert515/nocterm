import 'dart:io';
import 'package:nocterm/nocterm.dart';

final _debugLog = File('infinite_hoverable_list_demo_debug.log');

void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  _debugLog.writeAsStringSync('[$timestamp] $message\n', mode: FileMode.append);
}

void main() {
  if (_debugLog.existsSync()) {
    _debugLog.deleteSync();
  }

  runApp(const InfiniteHoverableListDemo());
}

class InfiniteHoverableListDemo extends StatefulComponent {
  const InfiniteHoverableListDemo({super.key});

  @override
  State<InfiniteHoverableListDemo> createState() =>
      _InfiniteHoverableListDemoState();
}

class _InfiniteHoverableListDemoState extends State<InfiniteHoverableListDemo> {
  int? _hoveredIndex;
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: BoxBorder.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0066CC),
              border: BoxBorder(bottom: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              '∞ INFINITE HOVERABLE LIST',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),

          // Info bar
          Container(
            decoration: const BoxDecoration(
              border: BoxBorder(bottom: BorderSide()),
              color: Color(0xFF222222),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                const Text(
                  'Selected: ',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
                Text(
                  _selectedIndex != null ? 'Item $_selectedIndex' : 'None',
                  style: TextStyle(
                    color: _selectedIndex != null
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF888888),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Text(
                  '💡 Scroll with mouse wheel or arrow keys',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ],
            ),
          ),

          // Scrollable list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: null, // Infinite!
              itemBuilder: (context, index) {
                return _buildListItem(index);
              },
            ),
          ),

          // Footer
          Container(
            decoration: const BoxDecoration(
              border: BoxBorder(top: BorderSide()),
              color: Color(0xFF222222),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: const Text(
              'List continues infinitely... keep scrolling! ↓',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildListItem(int index) {
    final isHovered = _hoveredIndex == index;
    final isSelected = _selectedIndex == index;

    // Generate different item types based on index
    final itemType = _getItemType(index);
    final icon = _getItemIcon(itemType);
    final color = _getItemColor(itemType);

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _hoveredIndex = index;
        });
        _log('Item $index - Hover ENTER');
      },
      onExit: (event) {
        setState(() {
          _hoveredIndex = null;
        });
        _log('Item $index - Hover EXIT');
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          _log('Item $index - SELECTED');
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Color.fromARGB(
                    (0.3 * 255).round(),
                    color.red,
                    color.green,
                    color.blue,
                  )
                : isHovered
                ? const Color(0xFF333333)
                : null,
            border: const BoxBorder(bottom: BorderSide()),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Row(
            children: [
              // Index number
              Container(
                width: 8,
                alignment: Alignment.centerRight,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: isSelected || isHovered
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF666666),
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Icon
              Text(
                icon,
                style: TextStyle(color: isSelected || isHovered ? color : null),
              ),
              const SizedBox(width: 2),
              // Label
              Expanded(
                child: Text(
                  _getItemLabel(index, itemType),
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
              // Status indicators
              if (isSelected)
                const Text(
                  '✓',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (isHovered)
                Text(
                  '→',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getItemType(int index) {
    final types = [
      'file',
      'folder',
      'image',
      'video',
      'audio',
      'code',
      'document',
      'archive',
    ];
    return types[index % types.length];
  }

  String _getItemIcon(String type) {
    return switch (type) {
      'file' => '📄',
      'folder' => '📁',
      'image' => '🖼',
      'video' => '🎬',
      'audio' => '🎵',
      'code' => '💻',
      'document' => '📝',
      'archive' => '📦',
      _ => '❓',
    };
  }

  Color _getItemColor(String type) {
    return switch (type) {
      'file' => const Color(0xFF888888),
      'folder' => const Color(0xFFFFAA00),
      'image' => const Color(0xFFFF00FF),
      'video' => const Color(0xFF00AAFF),
      'audio' => const Color(0xFF00FF00),
      'code' => const Color(0xFFFF6600),
      'document' => const Color(0xFF0088FF),
      'archive' => const Color(0xFFAA00AA),
      _ => const Color(0xFF666666),
    };
  }

  String _getItemLabel(int index, String type) {
    final typeLabel = type[0].toUpperCase() + type.substring(1);
    return '$typeLabel Item $index';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
