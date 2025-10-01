import 'dart:async';
import 'dart:math' as math;
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/decorated_box.dart';

void main() async {
  await runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatefulComponent {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Dashboard', 'Processes', 'Performance', 'Network'];
  Timer? _updateTimer;

  // Mock data
  List<ProcessInfo> _processes = [];
  SystemStats _systemStats = SystemStats();
  List<NetworkConnection> _connections = [];
  List<double> _cpuHistory = List.generate(30, (_) => 0.0);
  List<double> _memoryHistory = List.generate(30, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _updateTimer = Timer.periodic(Duration(seconds: 1), (_) => _updateData());
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeMockData() {
    final random = math.Random();

    // Generate mock processes
    _processes = [
      ProcessInfo('system', 1, 2.3, 145.2, 'Running', 'root'),
      ProcessInfo('terminal', 1234, 0.8, 89.5, 'Running', 'user'),
      ProcessInfo('dart', 2345, 15.2, 256.8, 'Running', 'user'),
      ProcessInfo('chrome', 3456, 8.5, 1024.5, 'Running', 'user'),
      ProcessInfo('vscode', 4567, 5.2, 512.3, 'Running', 'user'),
      ProcessInfo('docker', 5678, 3.1, 256.7, 'Running', 'root'),
      ProcessInfo('postgres', 6789, 1.5, 128.4, 'Running', 'postgres'),
      ProcessInfo('redis', 7890, 0.5, 64.2, 'Running', 'redis'),
      ProcessInfo('nginx', 8901, 0.3, 32.1, 'Running', 'www'),
      ProcessInfo('node', 9012, 4.2, 256.9, 'Running', 'user'),
    ];

    // Generate mock network connections
    _connections = [
      NetworkConnection('TCP', '127.0.0.1:8080', '0.0.0.0:*', 'LISTEN', 'dart'),
      NetworkConnection('TCP', '192.168.1.100:52341', '142.250.185.46:443', 'ESTABLISHED', 'chrome'),
      NetworkConnection('TCP', '127.0.0.1:5432', '127.0.0.1:54321', 'ESTABLISHED', 'postgres'),
      NetworkConnection('UDP', '0.0.0.0:53', '*:*', 'LISTEN', 'systemd-resolved'),
      NetworkConnection('TCP', ':::80', ':::*', 'LISTEN', 'nginx'),
    ];

    // Initialize CPU/Memory history
    for (int i = 0; i < _cpuHistory.length; i++) {
      _cpuHistory[i] = 20 + random.nextDouble() * 60;
      _memoryHistory[i] = 40 + random.nextDouble() * 40;
    }
  }

  void _updateData() {
    setState(() {
      final random = math.Random();

      // Update system stats
      _systemStats.cpuUsage = 20 + random.nextDouble() * 60;
      _systemStats.memoryUsage = 40 + random.nextDouble() * 40;
      _systemStats.diskUsage = 60 + random.nextDouble() * 20;
      _systemStats.networkIn = random.nextDouble() * 100;
      _systemStats.networkOut = random.nextDouble() * 50;
      _systemStats.uptime =
          DateTime.now().difference(DateTime.now().subtract(Duration(days: 5, hours: 12, minutes: 34)));

      // Update CPU/Memory history
      _cpuHistory.removeAt(0);
      _cpuHistory.add(_systemStats.cpuUsage);
      _memoryHistory.removeAt(0);
      _memoryHistory.add(_systemStats.memoryUsage);

      // Randomly update process CPU usage
      for (var process in _processes) {
        process.cpu = math.max(0, process.cpu + (random.nextDouble() - 0.5) * 5);
      }
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
        } else if (event.logicalKey == LogicalKey.tab) {
          setState(() {
            _selectedTab = (_selectedTab + 1) % _tabs.length;
          });
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF0D1117),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(1),
                child: _buildContent(),
              ),
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
        gradient: LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: BoxBorder(
          bottom: BorderSide(color: Color(0xFF374151), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('⚡', style: TextStyle(color: Color(0xFF60A5FA))),
              SizedBox(width: 1),
              Text('System Monitor',
                  style: TextStyle(
                    color: Color(0xFFF3F4F6),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          Text(DateTime.now().toString().substring(11, 19), style: TextStyle(color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Component _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        border: BoxBorder(
          bottom: BorderSide(color: Color(0xFF374151), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++) _buildTab(_tabs[i], i == _selectedTab, i),
        ],
      ),
    );
  }

  Component _buildTab(String title, bool isSelected, int index) {
    final shortcut = (index + 1).toString();
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF0D1117) : null,
        border: isSelected
            ? BoxBorder(
                left: BorderSide(color: Color(0xFF374151), width: 1),
                right: BorderSide(color: Color(0xFF374151), width: 1),
                top: BorderSide(color: Color(0xFF60A5FA), width: 2),
              )
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        children: [
          Text('[$shortcut]',
              style: TextStyle(
                color: Color(0xFF6B7280),
              )),
          SizedBox(width: 1),
          Text(title,
              style: TextStyle(
                color: isSelected ? Color(0xFFF3F4F6) : Color(0xFF9CA3AF),
                fontWeight: isSelected ? FontWeight.bold : null,
              )),
        ],
      ),
    );
  }

  Component _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildProcesses();
      case 2:
        return _buildPerformance();
      case 3:
        return _buildNetwork();
      default:
        return Container();
    }
  }

  Component _buildDashboard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'CPU', '${_systemStats.cpuUsage.toStringAsFixed(1)}%', _systemStats.cpuUsage, Color(0xFF3B82F6))),
            SizedBox(width: 1),
            Expanded(
                child: _buildStatCard('Memory', '${_systemStats.memoryUsage.toStringAsFixed(1)}%',
                    _systemStats.memoryUsage, Color(0xFF8B5CF6))),
            SizedBox(width: 1),
            Expanded(
                child: _buildStatCard('Disk', '${_systemStats.diskUsage.toStringAsFixed(1)}%', _systemStats.diskUsage,
                    Color(0xFF10B981))),
          ],
        ),
        SizedBox(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildQuickInfo(),
              ),
              SizedBox(width: 1),
              Expanded(
                child: _buildTopProcesses(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Component _buildStatCard(String label, String value, double percentage, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        border: BoxBorder.all(color: Color(0xFF374151)),
        borderRadius: BorderRadius.circular(1),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF9CA3AF))),
          Text(value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(height: 1),
          _buildMiniProgressBar(percentage, color),
        ],
      ),
    );
  }

  Component _buildMiniProgressBar(double percentage, Color color) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        color: Color(0xFF374151),
      ),
      child: Row(
        children: [
          Expanded(
            flex: percentage.round(),
            child: Container(
              decoration: BoxDecoration(color: color),
            ),
          ),
          Expanded(
            flex: (100 - percentage).round(),
            child: Container(),
          ),
        ],
      ),
    );
  }

  Component _buildQuickInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        border: BoxBorder.all(color: Color(0xFF374151)),
      ),
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Information',
              style: TextStyle(
                color: Color(0xFFF3F4F6),
                fontWeight: FontWeight.bold,
              )),
          SizedBox(height: 1),
          _buildInfoRow('Uptime', _formatDuration(_systemStats.uptime)),
          _buildInfoRow('Processes', '${_processes.length} running'),
          _buildInfoRow('Network ↓', '${_systemStats.networkIn.toStringAsFixed(1)} MB/s'),
          _buildInfoRow('Network ↑', '${_systemStats.networkOut.toStringAsFixed(1)} MB/s'),
          _buildInfoRow('Load Average', '2.14, 1.89, 1.95'),
          _buildInfoRow('Temperature', '${45 + _systemStats.cpuUsage / 10}°C'),
        ],
      ),
    );
  }

  Component _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF9CA3AF))),
          Text(value, style: TextStyle(color: Color(0xFFF3F4F6))),
        ],
      ),
    );
  }

  Component _buildTopProcesses() {
    final topProcesses = List<ProcessInfo>.from(_processes)
      ..sort((a, b) => b.cpu.compareTo(a.cpu))
      ..take(5);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        border: BoxBorder.all(color: Color(0xFF374151)),
      ),
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Processes',
              style: TextStyle(
                color: Color(0xFFF3F4F6),
                fontWeight: FontWeight.bold,
              )),
          SizedBox(height: 1),
          Expanded(
            child: Column(
              children: topProcesses
                  .take(5)
                  .map(
                    (process) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              process.name,
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                          ),
                          Text('${process.cpu.toStringAsFixed(1)}%',
                              style: TextStyle(color: _getCpuColor(process.cpu))),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCpuColor(double cpu) {
    if (cpu > 80) return Color(0xFFEF4444);
    if (cpu > 50) return Color(0xFFF59E0B);
    if (cpu > 20) return Color(0xFF3B82F6);
    return Color(0xFF10B981);
  }

  Component _buildProcesses() {
    return Column(
      children: [
        _buildProcessHeader(),
        SizedBox(height: 1),
        Expanded(
          child: _buildProcessList(),
        ),
      ],
    );
  }

  Component _buildProcessHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        border: BoxBorder(
          bottom: BorderSide(color: Color(0xFF374151), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        children: [
          SizedBox(
              width: 15, child: Text('Name', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          SizedBox(
              width: 8, child: Text('PID', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          SizedBox(
              width: 8, child: Text('CPU %', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          SizedBox(
              width: 10,
              child: Text('Memory', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          SizedBox(
              width: 10,
              child: Text('Status', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          Expanded(child: Text('User', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Component _buildProcessList() {
    return Column(
      children: _processes.asMap().entries.map((entry) {
        final index = entry.key;
        final process = entry.value;
        final isEven = index % 2 == 0;

        return Container(
          decoration: BoxDecoration(
            color: isEven ? Color(0xFF1F2937) : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
          child: Row(
            children: [
              SizedBox(width: 15, child: Text(process.name, style: TextStyle(color: Color(0xFFF3F4F6)))),
              SizedBox(width: 8, child: Text(process.pid.toString(), style: TextStyle(color: Color(0xFF9CA3AF)))),
              SizedBox(
                  width: 8,
                  child: Text(process.cpu.toStringAsFixed(1), style: TextStyle(color: _getCpuColor(process.cpu)))),
              SizedBox(
                  width: 10,
                  child: Text('${process.memory.toStringAsFixed(1)}M', style: TextStyle(color: Color(0xFF9CA3AF)))),
              SizedBox(width: 10, child: Text(process.status, style: TextStyle(color: Color(0xFF10B981)))),
              Expanded(child: Text(process.user, style: TextStyle(color: Color(0xFF9CA3AF)))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Component _buildPerformance() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF1F2937),
              border: BoxBorder.all(color: Color(0xFF374151)),
            ),
            padding: EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CPU Usage History',
                    style: TextStyle(
                      color: Color(0xFFF3F4F6),
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 1),
                Expanded(child: _buildGraph(_cpuHistory, Color(0xFF3B82F6))),
              ],
            ),
          ),
        ),
        SizedBox(height: 1),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF1F2937),
              border: BoxBorder.all(color: Color(0xFF374151)),
            ),
            padding: EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Memory Usage History',
                    style: TextStyle(
                      color: Color(0xFFF3F4F6),
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 1),
                Expanded(child: _buildGraph(_memoryHistory, Color(0xFF8B5CF6))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Component _buildGraph(List<double> data, Color color) {
    // Create ASCII art graph
    final maxValue = data.reduce(math.max);
    final height = 10;

    return Column(
      children: List.generate(height, (row) {
        final threshold = maxValue * (height - row) / height;
        return Row(
          children: data.map((value) {
            final char = value >= threshold ? '█' : ' ';
            return Text(char, style: TextStyle(color: color));
          }).toList(),
        );
      }),
    );
  }

  Component _buildNetwork() {
    return Column(
      children: [
        _buildNetworkHeader(),
        SizedBox(height: 1),
        Expanded(
          child: _buildConnectionList(),
        ),
      ],
    );
  }

  Component _buildNetworkHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        border: BoxBorder(
          bottom: BorderSide(color: Color(0xFF374151), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        children: [
          SizedBox(
              width: 8, child: Text('Proto', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          SizedBox(
              width: 25,
              child: Text('Local Address', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          SizedBox(
              width: 25,
              child: Text('Remote Address', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          SizedBox(
              width: 12, child: Text('State', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
          Expanded(child: Text('Process', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Component _buildConnectionList() {
    return Column(
      children: _connections.asMap().entries.map((entry) {
        final index = entry.key;
        final conn = entry.value;
        final isEven = index % 2 == 0;

        return Container(
          decoration: BoxDecoration(
            color: isEven ? Color(0xFF1F2937) : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
          child: Row(
            children: [
              SizedBox(width: 8, child: Text(conn.protocol, style: TextStyle(color: Color(0xFFF3F4F6)))),
              SizedBox(width: 25, child: Text(conn.localAddress, style: TextStyle(color: Color(0xFF60A5FA)))),
              SizedBox(width: 25, child: Text(conn.remoteAddress, style: TextStyle(color: Color(0xFF9CA3AF)))),
              SizedBox(width: 12, child: Text(conn.state, style: TextStyle(color: _getStateColor(conn.state)))),
              Expanded(child: Text(conn.process, style: TextStyle(color: Color(0xFF9CA3AF)))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'ESTABLISHED':
        return Color(0xFF10B981);
      case 'LISTEN':
        return Color(0xFF3B82F6);
      case 'CLOSE_WAIT':
        return Color(0xFFF59E0B);
      default:
        return Color(0xFF9CA3AF);
    }
  }

  Component _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        border: BoxBorder(
          top: BorderSide(color: Color(0xFF374151), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('[TAB] Navigate', style: TextStyle(color: Color(0xFF6B7280))),
              SizedBox(width: 2),
              Text('[1-4] Jump to tab', style: TextStyle(color: Color(0xFF6B7280))),
              SizedBox(width: 2),
              Text('[Q] Quit', style: TextStyle(color: Color(0xFF6B7280))),
            ],
          ),
          Text('v1.0.0', style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    return '${days}d ${hours}h ${minutes}m';
  }
}

// Model classes
class ProcessInfo {
  final String name;
  final int pid;
  double cpu;
  final double memory;
  final String status;
  final String user;

  ProcessInfo(this.name, this.pid, this.cpu, this.memory, this.status, this.user);
}

class SystemStats {
  double cpuUsage = 0;
  double memoryUsage = 0;
  double diskUsage = 0;
  double networkIn = 0;
  double networkOut = 0;
  Duration uptime = Duration.zero;
}

class NetworkConnection {
  final String protocol;
  final String localAddress;
  final String remoteAddress;
  final String state;
  final String process;

  NetworkConnection(this.protocol, this.localAddress, this.remoteAddress, this.state, this.process);
}
