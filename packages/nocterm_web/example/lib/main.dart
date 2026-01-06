import 'dart:async';
import 'dart:math' as math;
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const InteractiveDemo());
}

// Interactive Demo App - showcasing nocterm capabilities
class InteractiveDemo extends StatefulComponent {
  const InteractiveDemo({super.key});

  @override
  State<InteractiveDemo> createState() => _InteractiveDemoState();
}

class _InteractiveDemoState extends State<InteractiveDemo> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Dashboard', 'Widgets', 'Animation', 'About'];
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateTime.now().toString().substring(11, 19);
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.digit1) {
          setState(() => _selectedTab = 0);
          return true;
        } else if (event.logicalKey == LogicalKey.digit2) {
          setState(() => _selectedTab = 1);
          return true;
        } else if (event.logicalKey == LogicalKey.digit3) {
          setState(() => _selectedTab = 2);
          return true;
        } else if (event.logicalKey == LogicalKey.digit4) {
          setState(() => _selectedTab = 3);
          return true;
        } else if (event.logicalKey == LogicalKey.arrowLeft) {
          setState(() {
            _selectedTab = (_selectedTab - 1).clamp(0, _tabs.length - 1);
          });
          return true;
        } else if (event.logicalKey == LogicalKey.arrowRight) {
          setState(() {
            _selectedTab = (_selectedTab + 1).clamp(0, _tabs.length - 1);
          });
          return true;
        }
        return false;
      },
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFF1A1B26)),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Component _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2D2E40),
        border: BoxBorder(bottom: BorderSide(color: Color(0xFF565869))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        children: [
          const Text('🚀 ', style: TextStyle(color: Colors.cyan)),
          const Text(
            'nocterm Web Demo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(_currentTime, style: const TextStyle(color: Color(0xFF7AA2F7))),
        ],
      ),
    );
  }

  Component _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF24253A)),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: i == _selectedTab ? const Color(0xFF2D2E40) : null,
                  border: i == _selectedTab
                      ? const BoxBorder(
                          bottom: BorderSide(
                            color: Color(0xFF7AA2F7),
                            width: 2,
                          ),
                        )
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      color: i == _selectedTab
                          ? const Color(0xFF7AA2F7)
                          : const Color(0xFF565869),
                      fontWeight: i == _selectedTab ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Component _buildContent() {
    switch (_selectedTab) {
      case 0:
        return const DashboardTab();
      case 1:
        return const WidgetsTab();
      case 2:
        return const AnimationTab();
      case 3:
        return const AboutTab();
      default:
        return Container();
    }
  }

  Component _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2D2E40),
        border: BoxBorder(top: BorderSide(color: Color(0xFF565869))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: const Row(
        children: [
          Text('←→: Switch Tabs', style: TextStyle(color: Color(0xFF565869))),
          Text(' | ', style: TextStyle(color: Color(0xFF565869))),
          Text('1-4: Quick Jump', style: TextStyle(color: Color(0xFF565869))),
          Spacer(),
          Text('nocterm v1.0', style: TextStyle(color: Color(0xFF7AA2F7))),
        ],
      ),
    );
  }
}

// Dashboard Tab with live metrics
class DashboardTab extends StatefulComponent {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Timer? _timer;
  List<double> _cpuHistory = List.generate(20, (_) => 0.0);
  double _cpu = 0.0;
  double _memory = 0.0;
  double _network = 0.0;
  int _requests = 0;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        _cpu = 20 + _random.nextDouble() * 60;
        _memory = 40 + _random.nextDouble() * 30;
        _network = 10 + _random.nextDouble() * 50;
        _requests += _random.nextInt(10);
        _cpuHistory = [..._cpuHistory.skip(1), _cpu];
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'CPU',
                  '${_cpu.toStringAsFixed(1)}%',
                  Colors.cyan,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildStatCard(
                  'Memory',
                  '${_memory.toStringAsFixed(1)}%',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildStatCard(
                  'Network',
                  '${_network.toStringAsFixed(1)} MB/s',
                  Colors.yellow,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildStatCard('Requests', '$_requests', Colors.magenta),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildSystemMonitor()),
                const SizedBox(width: 2),
                Expanded(child: _buildActivityFeed()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Component _buildStatCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF565869))),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Component _buildSystemMonitor() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 System Monitor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          _buildProgressBar('CPU', _cpu, Colors.cyan),
          _buildProgressBar('MEM', _memory, Colors.green),
          _buildProgressBar('NET', _network, Colors.yellow),
          const SizedBox(height: 1),
          const Text('CPU History', style: TextStyle(color: Color(0xFF565869))),
          _buildSparkline(),
        ],
      ),
    );
  }

  Component _buildProgressBar(String label, double value, Color color) {
    final barLength = 20;
    final filledLength = (value / 100 * barLength).round();
    final emptyLength = barLength - filledLength;

    return Row(
      children: [
        SizedBox(
          width: 4,
          child: Text(label, style: const TextStyle(color: Color(0xFF565869))),
        ),
        Text('█' * filledLength, style: TextStyle(color: color)),
        Text(
          '░' * emptyLength,
          style: const TextStyle(color: Color(0xFF565869)),
        ),
        const SizedBox(width: 1),
        Text('${value.toStringAsFixed(0)}%', style: TextStyle(color: color)),
      ],
    );
  }

  Component _buildSparkline() {
    String sparkline = '';
    const chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    for (double value in _cpuHistory) {
      int index = ((value / 100) * (chars.length - 1)).round();
      sparkline += chars[index];
    }
    return Text(sparkline, style: const TextStyle(color: Color(0xFF7AA2F7)));
  }

  Component _buildActivityFeed() {
    final activities = [
      ('🟢', 'User login', '2m'),
      ('🔵', 'API call', '5m'),
      ('🟡', 'DB query', '8m'),
      ('🟢', 'Deploy', '1h'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Activity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Column(
              children: [
                for (var activity in activities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Row(
                      children: [
                        Text(activity.$1),
                        const SizedBox(width: 1),
                        Expanded(
                          child: Text(
                            activity.$2,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Text(
                          activity.$3,
                          style: const TextStyle(color: Color(0xFF565869)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widgets Tab showcasing different components
class WidgetsTab extends StatefulComponent {
  const WidgetsTab({super.key});

  @override
  State<WidgetsTab> createState() => _WidgetsTabState();
}

class _WidgetsTabState extends State<WidgetsTab> {
  int _counter = 0;
  int _selectedItem = 0;
  bool _toggleOn = false;
  final List<String> _items = ['Option A', 'Option B', 'Option C', 'Option D'];

  @override
  Component build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(child: _buildCounterDemo()),
          const SizedBox(width: 2),
          Expanded(child: _buildSelectionDemo()),
          const SizedBox(width: 2),
          Expanded(child: _buildStylesDemo()),
        ],
      ),
    );
  }

  Component _buildCounterDemo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '🔢 Counter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '$_counter',
            style: const TextStyle(
              color: Color(0xFF7AA2F7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _counter--),
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFF565869)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  child: const Text('-', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: () => setState(() => _counter++),
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFF7AA2F7)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  child: const Text(
                    '+',
                    style: TextStyle(color: Color(0xFF1A1B26)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _toggleOn = !_toggleOn),
                child: Text(
                  _toggleOn ? '◉ ON ' : '○ OFF',
                  style: TextStyle(
                    color: _toggleOn ? Colors.green : const Color(0xFF565869),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Component _buildSelectionDemo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Selection',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          for (int i = 0; i < _items.length; i++)
            GestureDetector(
              onTap: () => setState(() => _selectedItem = i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Row(
                  children: [
                    Text(
                      _selectedItem == i ? '▶ ' : '  ',
                      style: const TextStyle(color: Color(0xFF7AA2F7)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _selectedItem == i
                            ? const Color(0xFF2D2E40)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Text(
                        _items[i],
                        style: TextStyle(
                          color: _selectedItem == i
                              ? const Color(0xFF7AA2F7)
                              : Colors.white,
                        ),
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

  Component _buildStylesDemo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎨 Text Styles',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1),
          Text(
            'Bold text',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Italic text',
            style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
          ),
          Text(
            'Underlined',
            style: TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
          Text(
            'Dim text',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.dim),
          ),
          Text('Cyan', style: TextStyle(color: Colors.cyan)),
          Text('Green', style: TextStyle(color: Colors.green)),
          Text('Yellow', style: TextStyle(color: Colors.yellow)),
          Text('Magenta', style: TextStyle(color: Colors.magenta)),
        ],
      ),
    );
  }
}

// Animation Tab with animated elements
class AnimationTab extends StatefulComponent {
  const AnimationTab({super.key});

  @override
  State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends State<AnimationTab> {
  Timer? _timer;
  int _frame = 0;
  int _spinnerFrame = 0;
  double _progressValue = 0.0;
  int _waveOffset = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _frame++;
        _spinnerFrame = (_spinnerFrame + 1) % 8;
        _progressValue = (_progressValue + 0.01) % 1.0;
        _waveOffset = (_waveOffset + 1) % 20;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSpinnerDemo()),
              const SizedBox(width: 2),
              Expanded(child: _buildProgressDemo()),
            ],
          ),
          const SizedBox(height: 2),
          Expanded(child: _buildWaveDemo()),
        ],
      ),
    );
  }

  Component _buildSpinnerDemo() {
    const spinnerChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧'];
    const altSpinners = ['◐', '◓', '◑', '◒'];
    const barSpinners = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔄 Spinners',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                spinnerChars[_spinnerFrame],
                style: const TextStyle(color: Colors.cyan),
              ),
              const SizedBox(width: 2),
              const Text('Loading...', style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Text(
                altSpinners[_spinnerFrame % 4],
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(width: 2),
              const Text(
                'Processing...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Text(
                barSpinners[_spinnerFrame],
                style: const TextStyle(color: Colors.yellow),
              ),
              const SizedBox(width: 2),
              const Text('Building...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Component _buildProgressDemo() {
    final barLength = 20;
    final filledLength = (_progressValue * barLength).round();
    final emptyLength = barLength - filledLength;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Progress',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '█' * filledLength,
                style: const TextStyle(color: Color(0xFF7AA2F7)),
              ),
              Text(
                '░' * emptyLength,
                style: const TextStyle(color: Color(0xFF565869)),
              ),
              Text(
                ' ${(_progressValue * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _buildBouncingProgress(),
        ],
      ),
    );
  }

  Component _buildBouncingProgress() {
    final barLength = 20;
    final position = (_frame ~/ 3) % (barLength * 2);
    final actualPos = position < barLength
        ? position
        : (barLength * 2 - position - 1);

    String bar = '';
    for (int i = 0; i < barLength; i++) {
      if (i == actualPos) {
        bar += '●';
      } else {
        bar += '─';
      }
    }

    return Text('[$bar]', style: const TextStyle(color: Colors.green));
  }

  Component _buildWaveDemo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF24253A),
        border: BoxBorder.all(color: const Color(0xFF565869)),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌊 Wave Animation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          _buildWave(),
          const SizedBox(height: 1),
          _buildColorGradient(),
        ],
      ),
    );
  }

  Component _buildWave() {
    const waveChars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    String wave = '';
    for (int i = 0; i < 40; i++) {
      final value =
          ((math.sin((i + _waveOffset) * 0.3) + 1) / 2 * (waveChars.length - 1))
              .round();
      wave += waveChars[value];
    }
    return Text(wave, style: const TextStyle(color: Color(0xFF7AA2F7)));
  }

  Component _buildColorGradient() {
    return Row(
      children: [
        for (int i = 0; i < 40; i++)
          Text(
            '█',
            style: TextStyle(
              color: Color.fromRGB(
                ((i + _waveOffset) * 6 % 256).round(),
                ((40 - i + _waveOffset) * 6 % 256).round(),
                200,
              ),
            ),
          ),
      ],
    );
  }
}

// About Tab
class AboutTab extends StatelessComponent {
  const AboutTab({super.key});

  @override
  Component build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF24253A),
            border: BoxBorder.all(color: const Color(0xFF7AA2F7), width: 2),
          ),
          padding: const EdgeInsets.all(3),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '╔═══════════════════════════════════╗',
                style: TextStyle(color: Color(0xFF7AA2F7)),
              ),
              Text(
                '║   🚀 NOCTERM WEB TERMINAL DEMO    ║',
                style: TextStyle(color: Color(0xFF7AA2F7)),
              ),
              Text(
                '╚═══════════════════════════════════╝',
                style: TextStyle(color: Color(0xFF7AA2F7)),
              ),
              SizedBox(height: 2),
              Text(
                'A powerful Terminal User Interface',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'running in your browser!',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 2),
              Text(
                '✨ Features',
                style: TextStyle(
                  color: Color(0xFF7AA2F7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1),
              Text(
                '• Flutter-like component system',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '• Reactive state management',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '• Rich text and color support',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '• Mouse and keyboard input',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '• Animations and timers',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 2),
              Text(
                '🛠️ Built with Dart',
                style: TextStyle(color: Color(0xFF565869)),
              ),
              Text(
                '💙 Powered by nocterm',
                style: TextStyle(color: Color(0xFF565869)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
