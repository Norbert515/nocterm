import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const MultipleScrollablesTest());
}

class MultipleScrollablesTest extends StatelessComponent {
  const MultipleScrollablesTest({super.key});
  
  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Colors.cyan),
          ),
          child: Center(
            child: Text(
              'Multiple Scrollables Test - Hover and scroll different areas',
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        // Main content area with side-by-side scrollables
        Expanded(
          child: Row(
            children: [
              // Left scrollable area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        padding: EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          'Left Panel (Green)',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < 50; i++)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    'Left ${i.toString().padLeft(2, '0')}: Item in left panel',
                                    style: TextStyle(
                                      color: i % 3 == 0 ? Colors.green : Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Middle scrollable area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        padding: EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          'Middle Panel (Blue)',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < 75; i++)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    'Mid ${i.toString().padLeft(2, '0')}: Content in middle',
                                    style: TextStyle(
                                      color: i % 4 == 0 ? Colors.blue : Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Right scrollable area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.magenta),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        padding: EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          'Right Panel (Magenta)',
                          style: TextStyle(color: Colors.magenta, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < 60; i++)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    'Right ${i.toString().padLeft(2, '0')}: Right panel text',
                                    style: TextStyle(
                                      color: i % 5 == 0 ? Colors.magenta : Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bottom area with horizontal scrollable
        Container(
          height: 8,
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Colors.yellow),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  'Bottom Panel (Yellow) - Also scrollable',
                  style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < 30; i++)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            'Bottom ${i}: This is a message in the bottom scrollable area that might be quite long',
                            style: TextStyle(
                              color: i % 2 == 0 ? Colors.yellow : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Status bar
        Container(
          height: 2,
          decoration: BoxDecoration(
            border: BoxBorder(top: BorderSide(color: Colors.gray)),
          ),
          child: Text(
            'ESC to exit | Hover mouse over different panels and scroll with wheel/trackpad',
            style: TextStyle(color: Colors.gray),
          ),
        ),
      ],
    );
  }
}