import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const TextTabsDemo());
}

class TextTabsDemo extends StatefulComponent {
  const TextTabsDemo({super.key});

  @override
  State<TextTabsDemo> createState() => _TextTabsDemoState();
}

class _TextTabsDemoState extends State<TextTabsDemo> {
  int selectedTab = 0;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          setState(() {
            selectedTab = (selectedTab + 1) % 4;
          });
          return true;
        }
        return false;
      },
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.cyan),
            ),
            child: Center(
              child: Text(
                'Text Components Demo',
                style: TextStyle(
                  color: Colors.brightCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Tab navigation
          Container(
            padding: EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab('Basic Text', 0),
                Text(' | '),
                _buildTab('Styled Text', 1),
                Text(' | '),
                _buildTab('Layout Text', 2),
                Text(' | '),
                _buildTab('Color Text', 3),
              ],
            ),
          ),

          // Content area
          Expanded(child: _buildContent()),

          // Instructions
          Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder(top: BorderSide(color: Colors.gray)),
            ),
            child: Text(
              'Use Tab to switch between different text demos',
              style: TextStyle(color: Colors.gray),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildTab(String label, int index) {
    final isSelected = selectedTab == index;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2),
      decoration: isSelected ? BoxDecoration(color: Colors.blue) : null,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.brightWhite : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Component _buildContent() {
    switch (selectedTab) {
      case 0:
        return _buildBasicTextDemo();
      case 1:
        return _buildStyledTextDemo();
      case 2:
        return _buildLayoutTextDemo();
      case 3:
        return _buildColorTextDemo();
      default:
        return Container();
    }
  }

  Component _buildBasicTextDemo() {
    return Padding(
      padding: EdgeInsets.all(1),
      child: Column(
        children: [
          Text(
            'Basic Text Demo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.green),
              ),
              padding: EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This is a simple text widget'),
                  SizedBox(height: 1),
                  Text('Text can be displayed in multiple lines'),
                  Text('Each Text widget creates a new line'),
                  SizedBox(height: 2),
                  Text('You can add spacing between text elements'),
                  SizedBox(height: 1),
                  Text('Text widgets are the foundation of TUI interfaces'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildStyledTextDemo() {
    return Padding(
      padding: EdgeInsets.all(1),
      child: Column(
        children: [
          Text(
            'Styled Text Demo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.magenta),
              ),
              padding: EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Regular text without any styling'),
                  SizedBox(height: 1),
                  Text(
                    'Bold text example',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Dim text example',
                    style: TextStyle(fontWeight: FontWeight.dim),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Italic text example',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Underlined text',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Strikethrough text',
                    style: TextStyle(decoration: TextDecoration.lineThrough),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Combined styling',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildLayoutTextDemo() {
    return Padding(
      padding: EdgeInsets.all(1),
      child: Column(
        children: [
          Text(
            'Layout Text Demo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Row(
              children: [
                // Left column
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.yellow),
                    ),
                    padding: EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Left Column',
                          style: TextStyle(color: Colors.yellow),
                        ),
                        SizedBox(height: 1),
                        Text('Text aligned to start'),
                        Text('Multiple lines'),
                        Text('In a column layout'),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 2),

                // Center column
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.blue),
                    ),
                    padding: EdgeInsets.all(2),
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            'Center Column',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        SizedBox(height: 1),
                        Center(child: Text('Centered text')),
                        Center(child: Text('In the middle')),
                        Center(child: Text('Of the column')),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 2),

                // Right column
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.red),
                    ),
                    padding: EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Right Column',
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 1),
                        Text('Text aligned to end'),
                        Text('Right side'),
                        Text('Alignment demo'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Component _buildColorTextDemo() {
    return Padding(
      padding: EdgeInsets.all(1),
      child: Column(
        children: [
          Text(
            'Color Text Demo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              padding: EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Colors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1),
                  Text('Red text', style: TextStyle(color: Colors.red)),
                  Text('Green text', style: TextStyle(color: Colors.green)),
                  Text('Blue text', style: TextStyle(color: Colors.blue)),
                  Text('Yellow text', style: TextStyle(color: Colors.yellow)),
                  Text('Magenta text', style: TextStyle(color: Colors.magenta)),
                  Text('Cyan text', style: TextStyle(color: Colors.cyan)),
                  Text('White text', style: TextStyle(color: Colors.white)),
                  Text('Gray text', style: TextStyle(color: Colors.gray)),
                  SizedBox(height: 2),
                  Text(
                    'Bright Colors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1),
                  Text('Bright Red', style: TextStyle(color: Colors.brightRed)),
                  Text(
                    'Bright Green',
                    style: TextStyle(color: Colors.brightGreen),
                  ),
                  Text(
                    'Bright Blue',
                    style: TextStyle(color: Colors.brightBlue),
                  ),
                  Text(
                    'Bright Yellow',
                    style: TextStyle(color: Colors.brightYellow),
                  ),
                  Text(
                    'Bright Magenta',
                    style: TextStyle(color: Colors.brightMagenta),
                  ),
                  Text(
                    'Bright Cyan',
                    style: TextStyle(color: Colors.brightCyan),
                  ),
                  Text(
                    'Bright White',
                    style: TextStyle(color: Colors.brightWhite),
                  ),
                  SizedBox(height: 2),
                  Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Text(
                      'Text with background color',
                      style: TextStyle(color: Colors.brightWhite),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
