import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const StackSimpleStatefulDemo());
}

class StackSimpleStatefulDemo extends StatefulComponent {
  const StackSimpleStatefulDemo({super.key});

  @override
  State<StackSimpleStatefulDemo> createState() =>
      _StackSimpleStatefulDemoState();
}

class _StackSimpleStatefulDemoState extends State<StackSimpleStatefulDemo> {
  int counter = 0;
  String selectedColor = 'blue';
  bool showInfo = true;

  @override
  void initState() {
    super.initState();
    // Simulate automatic counter increment every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          counter++;
        });
      }
    });

    // Change color after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          selectedColor = 'green';
        });
      }
    });

    // Toggle info box after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showInfo = false;
        });
      }
    });
  }

  Color getColor() {
    switch (selectedColor) {
      case 'blue':
        return const Color.fromRGB(50, 50, 150);
      case 'green':
        return const Color.fromRGB(50, 150, 50);
      case 'red':
        return const Color.fromRGB(150, 50, 50);
      default:
        return Colors.gray;
    }
  }

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        // Background layer
        Container(
          decoration: BoxDecoration(
            border: BoxBorder.all(style: BoxBorderStyle.double),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simple Stateful Stack Demo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text('This demo shows state changes over time'),
              const SizedBox(height: 1),
              Text('Counter value: $counter'),
              Text('Selected color: $selectedColor'),
              Text('Info box visible: ${showInfo ? "Yes" : "No"}'),
              const SizedBox(height: 2),
              const Text('Features:', style: TextStyle(color: Colors.cyan)),
              const Text('• Counter increments after 1 second'),
              const Text('• Color changes after 2 seconds'),
              const Text('• Info box hides after 3 seconds'),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: BoxBorder.all(),
                      color: selectedColor == 'blue' ? Colors.blue : null,
                    ),
                    child: const Text('Blue'),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: BoxBorder.all(),
                      color: selectedColor == 'green' ? Colors.green : null,
                    ),
                    child: const Text('Green'),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: BoxBorder.all(),
                      color: selectedColor == 'red' ? Colors.red : null,
                    ),
                    child: const Text('Red'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Floating counter display (top-right)
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
              color: getColor(),
            ),
            child: Text(
              'Count: $counter',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Info box (center-left) that can be toggled
        if (showInfo)
          Positioned(
            left: 5,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  style: BoxBorderStyle.double,
                  color: Colors.yellow,
                ),
                color: const Color.fromRGB(50, 50, 0),
              ),
              child: Column(
                children: [
                  const Text(
                    'INFO BOX',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Counter: $counter',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Color: $selectedColor',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Will hide in 3s',
                    style: TextStyle(color: Colors.gray),
                  ),
                ],
              ),
            ),
          ),

        // Status bar at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(color: getColor()),
            child: Center(
              child: Text(
                'Status: Active | Counter: $counter | Color: $selectedColor',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        StatefulChild(),
      ],
    );
  }
}

class StatefulChild extends StatefulComponent {
  const StatefulChild({super.key});

  @override
  State<StatefulChild> createState() => _StatefulChildState();
}

class _StatefulChildState extends State<StatefulChild> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    _startCounterLoop();
  }

  void _startCounterLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      setState(() {
        counter++;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: BoxBorder.all(color: Colors.red)),
      child: Text('Stateful Child: $counter'),
    );
  }
}
