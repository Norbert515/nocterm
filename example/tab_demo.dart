import 'dart:async';
import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const TabDemoApp());
}

class TabDemoApp extends StatelessComponent {
  const TabDemoApp({super.key});

  @override
  Component build(BuildContext context) {
    return NoctermApp(
      title: 'Tab Demo',
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulComponent {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTabIndex = 0;
  int _focusedFieldIndex = 0;

  double _progress1 = 0.0;
  double _progress2 = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _progress1 += 0.02;
          if (_progress1 > 1.0) _progress1 = 0.0;

          _progress2 += 0.005;
          if (_progress2 > 1.0) _progress2 = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(1),
          color: Colors.blue,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Tab Demo', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),

        // Tabs
        TabComponent(
          tabs: const ['Form Input', 'List View', 'Progress'],
          selectedIndex: _selectedTabIndex,
          onChanged: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
        ),

        // Content Area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(2),
            child: _buildSelectedContent(),
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.all(1),
          color: Colors.brightBlack,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ' Use Left/Right arrows or 1-3 to switch tabs. ',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                ' Press Ctrl+C or ESC or q to exit. ',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Component _buildSelectedContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildFormTab();
      case 1:
        return _buildListTab();
      case 2:
        return _buildProgressTab();
      default:
        return const Text('Unknown Tab');
    }
  }

  Component _buildFormTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter your details:'),
        const SizedBox(height: 1),
        const Text('Name:'),
        GestureDetector(
          onTap: () {
            setState(() {
              _focusedFieldIndex = 0;
            });
          },
          child: Container(
            width: 30,
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: TextField(
              placeholder: 'Type your name...',
              focused: _focusedFieldIndex == 0,
            ),
          ),
        ),
        const SizedBox(height: 1),
        const Text('Email:'),
        GestureDetector(
          onTap: () {
            setState(() {
              _focusedFieldIndex = 1;
            });
          },
          child: Container(
            width: 30,
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: TextField(
              placeholder: 'Type your email...',
              focused: _focusedFieldIndex == 1,
            ),
          ),
        ),
      ],
    );
  }

  Component _buildListTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select an item:'),
        const SizedBox(height: 1),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Text('List Item ${index + 1}'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Component _buildProgressTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Task Progress Tracker'),
        const SizedBox(height: 2),
        const Text('Downloading Files...'),
        const SizedBox(height: 1),
        Container(
          width: 40,
          child: ProgressBar(
            value: _progress1,
            valueColor: Colors.blue,
            backgroundColor: Colors.brightBlack,
            showPercentage: true,
          ),
        ),
        const SizedBox(height: 2),
        const Text('Processing Data...'),
        const SizedBox(height: 1),
        Container(
          width: 40,
          child: ProgressBar(
            value: _progress2,
            valueColor: Colors.magenta,
            backgroundColor: Colors.brightBlack,
            showPercentage: true,
          ),
        ),
      ],
    );
  }
}
