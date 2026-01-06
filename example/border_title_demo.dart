import 'package:nocterm/nocterm.dart';

class BorderTitleDemo extends StatefulComponent {
  @override
  State<BorderTitleDemo> createState() => _BorderTitleDemoState();
}

class _BorderTitleDemoState extends State<BorderTitleDemo> {
  final scrollController = ScrollController();

  @override
  Component build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Border Title Demo',
                style: TextStyle(
                  color: Colors.cyan,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 2),

              // Left-aligned title (default)
              Text(
                'Left-aligned title:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(style: BoxBorderStyle.rounded),
                  title: BorderTitle(text: 'Settings'),
                ),
                child: Center(child: Text('Content here')),
              ),
              SizedBox(height: 2),

              // Center-aligned title
              Text(
                'Center-aligned title:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(style: BoxBorderStyle.solid),
                  title: BorderTitle(
                    text: 'User Profile',
                    alignment: TitleAlignment.center,
                  ),
                ),
                child: Center(child: Text('Centered title')),
              ),
              SizedBox(height: 2),

              // Right-aligned title
              Text(
                'Right-aligned title:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(style: BoxBorderStyle.double),
                  title: BorderTitle(
                    text: 'Actions',
                    alignment: TitleAlignment.right,
                  ),
                ),
                child: Center(child: Text('Right-aligned')),
              ),
              SizedBox(height: 2),

              // Styled title
              Text(
                'Styled title with color:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                    color: Colors.cyan,
                    style: BoxBorderStyle.rounded,
                  ),
                  title: BorderTitle(
                    text: 'Important',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                child: Center(child: Text('Styled title')),
              ),
              SizedBox(height: 2),

              // Multiple panels side by side
              Text('Multiple panels:', style: TextStyle(color: Colors.yellow)),
              SizedBox(height: 1),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(
                          color: Colors.green,
                          style: BoxBorderStyle.rounded,
                        ),
                        title: BorderTitle(text: 'Input'),
                      ),
                      padding: EdgeInsets.all(1),
                      child: Text('Type here...'),
                    ),
                  ),
                  SizedBox(width: 1),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(
                          color: Colors.blue,
                          style: BoxBorderStyle.rounded,
                        ),
                        title: BorderTitle(text: 'Output'),
                      ),
                      padding: EdgeInsets.all(1),
                      child: Text('Results...'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),

              // Partial borders (no corners when sides don't connect)
              Text(
                'Partial borders (top only):',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder(
                    top: BorderSide(
                      color: Colors.magenta,
                      style: BoxBorderStyle.rounded,
                    ),
                  ),
                  title: BorderTitle(text: 'Section Header'),
                ),
                child: Text('No corners - just a line'),
              ),
              SizedBox(height: 2),

              // Top and bottom only
              Text(
                'Top + Bottom borders:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder(
                    top: BorderSide(
                      color: Colors.cyan,
                      style: BoxBorderStyle.solid,
                    ),
                    bottom: BorderSide(
                      color: Colors.cyan,
                      style: BoxBorderStyle.solid,
                    ),
                  ),
                  title: BorderTitle(text: 'Divider Style'),
                ),
                child: Center(child: Text('Horizontal dividers')),
              ),
              SizedBox(height: 2),

              Text(
                'Press Ctrl+C to exit',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(BorderTitleDemo());
}
