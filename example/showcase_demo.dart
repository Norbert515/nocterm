import 'dart:async';
import 'dart:math' as math;
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const ShowcaseApp());
}

class ShowcaseApp extends StatefulComponent {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Dashboard', 'Forms', 'Charts', 'Colors', 'About'];
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(Duration(seconds: 1), (_) => _updateTime());
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
        if (event.logicalKey == LogicalKey.keyQ) {
          shutdownApp();
        } else if (event.logicalKey == LogicalKey.digit1) {
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
        } else if (event.logicalKey == LogicalKey.digit5) {
          setState(() => _selectedTab = 4);
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
        decoration: BoxDecoration(
          color: Color(0xFF1A1B26),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _buildContent(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Component _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2D2E40),
        border: BoxBorder(
          bottom: BorderSide(color: Color(0xFF565869)),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        children: [
          Text(
            '🚀 ',
            style: TextStyle(color: Colors.cyan),
          ),
          Text(
            'Dart TUI Showcase',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Text(
            _currentTime,
            style: TextStyle(color: Color(0xFF7AA2F7)),
          ),
        ],
      ),
    );
  }

  Component _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF24253A),
      ),
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: i == _selectedTab ? Color(0xFF2D2E40) : null,
                  border: i == _selectedTab
                      ? BoxBorder(
                          bottom: BorderSide(
                            color: Color(0xFF7AA2F7),
                            width: 2,
                          ),
                        )
                      : null,
                ),
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      color: i == _selectedTab ? Color(0xFF7AA2F7) : Color(0xFF565869),
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
        return DashboardTab();
      case 1:
        return FormsTab();
      case 2:
        return ChartsTab();
      case 3:
        return ColorsTab();
      case 4:
        return AboutTab();
      default:
        return Container();
    }
  }

  Component _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2D2E40),
        border: BoxBorder(
          top: BorderSide(color: Color(0xFF565869)),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        children: [
          Text(
            'Tab: Navigate',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(' | ', style: TextStyle(color: Color(0xFF565869))),
          Text(
            'Enter: Select',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(' | ', style: TextStyle(color: Color(0xFF565869))),
          Text(
            '←→: Switch Tabs',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(' | ', style: TextStyle(color: Color(0xFF565869))),
          Text(
            '1-5: Quick Jump',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(' | ', style: TextStyle(color: Color(0xFF565869))),
          Text(
            'q: Quit',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Spacer(),
          Text(
            'v1.0.0',
            style: TextStyle(color: Color(0xFF7AA2F7)),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulComponent {
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Timer? _timer;
  List<double> _cpuHistory = List.generate(20, (_) => 0.0);
  double _cpu = 0.0;
  double _memory = 0.0;
  double _disk = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _cpu = 20 + math.Random().nextDouble() * 60;
        _memory = 40 + math.Random().nextDouble() * 30;
        _disk = 60 + math.Random().nextDouble() * 20;
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
      padding: EdgeInsets.all(2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Active Users', '1,234', Colors.green)),
              SizedBox(width: 2),
              Expanded(child: _buildStatCard('Revenue', '\$45.2K', Colors.cyan)),
              SizedBox(width: 2),
              Expanded(child: _buildStatCard('Orders', '567', Colors.yellow)),
              SizedBox(width: 2),
              Expanded(child: _buildStatCard('Growth', '+12.5%', Colors.magenta)),
            ],
          ),
          SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSystemMonitor(),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: _buildActivityFeed(),
                ),
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
        color: Color(0xFF24253A),
        border: BoxBorder.all(color: Color(0xFF565869)),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Color(0xFF565869)),
          ),
          SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Component _buildSystemMonitor() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF24253A),
        border: BoxBorder.all(color: Color(0xFF565869)),
      ),
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 System Monitor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          _buildProgressBar('CPU', _cpu, Colors.cyan),
          SizedBox(height: 1),
          _buildProgressBar('Memory', _memory, Colors.green),
          SizedBox(height: 1),
          _buildProgressBar('Disk', _disk, Colors.yellow),
          SizedBox(height: 2),
          Text(
            'CPU History',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          SizedBox(height: 1),
          _buildSparkline(),
        ],
      ),
    );
  }

  Component _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 8,
              child: Text(
                label,
                style: TextStyle(color: Color(0xFF565869)),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A1B26),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: value.toInt(),
                      child: Container(
                        decoration: BoxDecoration(color: color),
                        child: Text(
                          '█' * (value ~/ 5),
                          style: TextStyle(color: color),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: (100 - value).toInt(),
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 1),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(color: color),
            ),
          ],
        ),
      ],
    );
  }

  Component _buildSparkline() {
    String sparkline = '';
    final chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    for (double value in _cpuHistory) {
      int index = ((value / 100) * (chars.length - 1)).round();
      sparkline += chars[index];
    }
    return Text(
      sparkline,
      style: TextStyle(color: Color(0xFF7AA2F7)),
    );
  }

  Component _buildActivityFeed() {
    final activities = [
      ('🟢', 'User login', '2m ago'),
      ('🔵', 'Order placed', '5m ago'),
      ('🟡', 'Payment received', '12m ago'),
      ('🟢', 'New signup', '15m ago'),
      ('🔴', 'Error logged', '23m ago'),
      ('🟢', 'Backup complete', '1h ago'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF24253A),
        border: BoxBorder.all(color: Color(0xFF565869)),
      ),
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 Activity Feed',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: Column(
              children: [
                for (var activity in activities)
                  Padding(
                    padding: EdgeInsets.only(bottom: 1),
                    child: Row(
                      children: [
                        Text(activity.$1),
                        SizedBox(width: 1),
                        Expanded(
                          child: Text(
                            activity.$2,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Text(
                          activity.$3,
                          style: TextStyle(color: Color(0xFF565869)),
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

class FormsTab extends StatefulComponent {
  @override
  State<FormsTab> createState() => _FormsTabState();
}

class _FormsTabState extends State<FormsTab> {
  String _username = '';
  String _email = '';
  String _password = '';
  bool _newsletter = false;
  String _country = 'United States';
  int _selectedOption = 0;

  @override
  Component build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF24253A),
              border: BoxBorder.all(color: Color(0xFF565869)),
            ),
            padding: EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Registration Form',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                _buildFormField('Username', _username),
                SizedBox(height: 1),
                _buildFormField('Email', _email),
                SizedBox(height: 1),
                _buildFormField('Password', _password, isPassword: true),
                SizedBox(height: 2),
                Text(
                  'Country',
                  style: TextStyle(color: Color(0xFF565869)),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Color(0xFF565869)),
                    color: Color(0xFF1A1B26),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Text(
                    _country,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _newsletter ? '☑' : '☐',
                      style: TextStyle(color: Color(0xFF7AA2F7)),
                    ),
                    SizedBox(width: 1),
                    Text(
                      'Subscribe to newsletter',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Preferences',
                  style: TextStyle(color: Color(0xFF565869)),
                ),
                Column(
                  children: [
                    _buildRadioOption(0, 'Email notifications'),
                    _buildRadioOption(1, 'SMS notifications'),
                    _buildRadioOption(2, 'No notifications'),
                  ],
                ),
                SizedBox(height: 2),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF7AA2F7),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      color: Color(0xFF1A1B26),
                      fontWeight: FontWeight.bold,
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

  Component _buildFormField(String label, String value, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Color(0xFF565869)),
        ),
        Container(
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Color(0xFF565869)),
            color: Color(0xFF1A1B26),
          ),
          padding: EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            isPassword && value.isNotEmpty ? '•' * value.length : value,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Component _buildRadioOption(int value, String label) {
    return Row(
      children: [
        Text(
          _selectedOption == value ? '◉' : '○',
          style: TextStyle(color: Color(0xFF7AA2F7)),
        ),
        SizedBox(width: 1),
        Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

class ChartsTab extends StatefulComponent {
  @override
  State<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<ChartsTab> {
  @override
  Component build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(
            child: _buildBarChart(),
          ),
          SizedBox(width: 2),
          Expanded(
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Component _buildBarChart() {
    final data = [
      ('Jan', 65),
      ('Feb', 78),
      ('Mar', 45),
      ('Apr', 89),
      ('May', 72),
      ('Jun', 93),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF24253A),
        border: BoxBorder.all(color: Color(0xFF565869)),
      ),
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Sales by Month',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var item in data)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: (item.$2 / 10).round().toDouble(),
                              decoration: BoxDecoration(
                                color: Color(0xFF7AA2F7),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: List.generate(
                                    (item.$2 / 10).round(),
                                    (index) => Text(
                                      '█',
                                      style: TextStyle(color: Color(0xFF7AA2F7)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              item.$1,
                              style: TextStyle(color: Color(0xFF565869)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Component _buildLineChart() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF24253A),
        border: BoxBorder.all(color: Color(0xFF565869)),
      ),
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Growth Trend',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '100 ┤',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(
            ' 80 ┤    ╭─╮',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(
            ' 60 ┤  ╭─╯ ╰╮',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(
            ' 40 ┤ ╭╯    ╰─╮',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(
            ' 20 ┤╭╯       ╰╮',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(
            '  0 └──────────┘',
            style: TextStyle(color: Color(0xFF565869)),
          ),
          Text(
            '    Q1 Q2 Q3 Q4',
            style: TextStyle(color: Color(0xFF565869)),
          ),
        ],
      ),
    );
  }
}

class ColorsTab extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    final colors = [
      ('Black', Color(0xFF000000)),
      ('Red', Color(0xFFFF0000)),
      ('Green', Color(0xFF00FF00)),
      ('Yellow', Color(0xFFFFFF00)),
      ('Blue', Color(0xFF0000FF)),
      ('Magenta', Color(0xFFFF00FF)),
      ('Cyan', Color(0xFF00FFFF)),
      ('White', Color(0xFFFFFFFF)),
      ('Gray', Color(0xFF808080)),
      ('Orange', Color(0xFFFFA500)),
      ('Purple', Color(0xFF800080)),
      ('Pink', Color(0xFFFFC0CB)),
    ];

    return Padding(
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎨 Color Palette',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (int i = 0; i < colors.length ~/ 2; i++) _buildColorRow(colors[i].$1, colors[i].$2),
                    ],
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: Column(
                    children: [
                      for (int i = colors.length ~/ 2; i < colors.length; i++)
                        _buildColorRow(colors[i].$1, colors[i].$2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Color(0xFF565869)),
            ),
            padding: EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gradient Demo',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 1),
                Row(
                  children: [
                    for (int i = 0; i < 40; i++)
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGB(
                            (255 * (i / 40)).round(),
                            0,
                            (255 * (1 - i / 40)).round(),
                          ),
                        ),
                        child: Text('█'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Component _buildColorRow(String name, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: color),
            child: Text('    ', style: TextStyle(color: color)),
          ),
          SizedBox(width: 2),
          Text(
            name,
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Text(
            '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}'
                .toUpperCase(),
            style: TextStyle(color: Color(0xFF565869)),
          ),
        ],
      ),
    );
  }
}

class AboutTab extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF24253A),
            border: BoxBorder.all(color: Color(0xFF7AA2F7), width: 2),
          ),
          padding: EdgeInsets.all(3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '╔══════════════════════════════╗',
                style: TextStyle(color: Color(0xFF7AA2F7)),
              ),
              Text(
                '║     🚀 DART TUI FRAMEWORK    ║',
                style: TextStyle(color: Color(0xFF7AA2F7)),
              ),
              Text(
                '╚══════════════════════════════╝',
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
                'framework for Dart applications',
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
                '• Keyboard and focus handling',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '• Layout and styling system',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '• Testing framework included',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 2),
              Text(
                '🛠️ Built with Dart',
                style: TextStyle(color: Color(0xFF565869)),
              ),
              Text(
                '💙 Inspired by Flutter',
                style: TextStyle(color: Color(0xFF565869)),
              ),
              SizedBox(height: 2),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF7AA2F7),
                ),
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  'github.com/your-repo/dart-tui',
                  style: TextStyle(
                    color: Color(0xFF1A1B26),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
