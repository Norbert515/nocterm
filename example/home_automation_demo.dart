import 'dart:async';
import 'dart:math' as math;
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const HomeAutomationDashboard());
}

class HomeAutomationDashboard extends StatefulComponent {
  const HomeAutomationDashboard({super.key});

  @override
  State<HomeAutomationDashboard> createState() => _HomeAutomationDashboardState();
}

class _HomeAutomationDashboardState extends State<HomeAutomationDashboard> {
  int _selectedRoom = 0;
  final List<String> _rooms = ['Living Room', 'Kitchen', 'Bedroom', 'Office'];

  Timer? _clockTimer;
  String _currentTime = '';
  double _currentTemp = 23.0;
  int _humidity = 45;

  final Map<String, bool> _devices = {
    'lights': true,
    'lock': true,
    'security': true,
    'garage': false,
  };

  int _lightsOn = 4;
  final int _totalLights = 7;

  double _currentPower = 2.3;
  double _todayEnergy = 18.5;
  double _energyPercent = 0.35;

  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(Duration(seconds: 1), (_) => _updateTime());
    _startAnimations();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      final now = DateTime.now();
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final period = now.hour >= 12 ? 'PM' : 'AM';
      _currentTime =
          '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $period';
    });
  }

  void _startAnimations() {
    _animationTimer = Timer.periodic(Duration(seconds: 3), (_) {
      setState(() {
        _currentPower = 1.5 + (math.Random().nextDouble() * 2.0);
        _todayEnergy += 0.1;
        _energyPercent = 0.2 + (math.Random().nextDouble() * 0.4);

        _currentTemp = 22.0 + (math.Random().nextDouble() * 3.0);
        _humidity = 40 + math.Random().nextInt(20);
      });
    });
  }

  void _toggleDevice(String device) {
    setState(() {
      _devices[device] = !_devices[device]!;
      if (device == 'lights') {
        _lightsOn = _devices['lights']! ? 4 : 0;
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
          setState(() => _selectedRoom = 0);
          return true;
        } else if (event.logicalKey == LogicalKey.digit2) {
          setState(() => _selectedRoom = 1);
          return true;
        } else if (event.logicalKey == LogicalKey.digit3) {
          setState(() => _selectedRoom = 2);
          return true;
        } else if (event.logicalKey == LogicalKey.digit4) {
          setState(() => _selectedRoom = 3);
          return true;
        } else if (event.logicalKey == LogicalKey.arrowUp) {
          setState(() {
            _selectedRoom = (_selectedRoom - 1).clamp(0, _rooms.length - 1);
          });
          return true;
        } else if (event.logicalKey == LogicalKey.arrowDown) {
          setState(() {
            _selectedRoom = (_selectedRoom + 1).clamp(0, _rooms.length - 1);
          });
          return true;
        } else if (event.logicalKey == LogicalKey.space) {
          _toggleDevice('lights');
          return true;
        } else if (event.logicalKey == LogicalKey.keyL) {
          _toggleDevice('lock');
          return true;
        } else if (event.logicalKey == LogicalKey.keyS) {
          _toggleDevice('security');
          return true;
        } else if (event.logicalKey == LogicalKey.keyG) {
          _toggleDevice('garage');
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF0A0E27),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoomSelector(),
                    SizedBox(width: 1),
                    Expanded(
                      child: Column(
                        children: [
                          _buildClimatePanel(),
                          SizedBox(height: 1),
                          _buildDeviceControls(),
                          SizedBox(height: 1),
                          _buildEnergyMonitor(),
                        ],
                      ),
                    ),
                  ],
                ),
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
      height: 3,
      decoration: BoxDecoration(
        color: Color(0xFF1A1F3A),
        border: BoxBorder(
          bottom: BorderSide(color: Color(0xFF2A3F5F), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Smart Home Dashboard',
            style: TextStyle(
              color: Color(0xFF00D9FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                '${_currentTemp.toStringAsFixed(1)}°C',
                style: TextStyle(color: Color(0xFF00FF88)),
              ),
              SizedBox(width: 3),
              Text(
                _currentTime,
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Component _buildRoomSelector() {
    return Container(
      width: 20,
      decoration: BoxDecoration(
        border: BoxBorder.all(color: Color(0xFF2A3F5F)),
        borderRadius: BorderRadius.circular(1),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '── Rooms ──',
            style: TextStyle(color: Color(0xFF00D9FF)),
          ),
          SizedBox(height: 1),
          ...List.generate(_rooms.length, (index) {
            final isSelected = index == _selectedRoom;
            return Padding(
              padding: EdgeInsets.only(bottom: 0),
              child: Text(
                '${isSelected ? '▸ ' : '  '}${_rooms[index]}',
                style: TextStyle(
                  color: isSelected ? Color(0xFF00FF88) : Color(0xFF888888),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Component _buildClimatePanel() {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        border: BoxBorder.all(color: Color(0xFF2A3F5F)),
        borderRadius: BorderRadius.circular(1),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '── Climate ──',
            style: TextStyle(color: Color(0xFF00D9FF)),
          ),
          SizedBox(height: 1),
          Row(
            children: [
              Text('Temp:', style: TextStyle(color: Color(0xFF888888))),
              SizedBox(width: 1),
              Text(
                '${_currentTemp.toStringAsFixed(1)}°C',
                style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              Text('Humid:', style: TextStyle(color: Color(0xFF888888))),
              SizedBox(width: 1),
              Text(
                '$_humidity%',
                style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text('──────────────', style: TextStyle(color: Color(0xFF2A3F5F))),
          Row(
            children: [
              Text('Mode:', style: TextStyle(color: Color(0xFF888888))),
              SizedBox(width: 1),
              Text(
                'AUTO',
                style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Component _buildDeviceControls() {
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(color: Color(0xFF2A3F5F)),
        borderRadius: BorderRadius.circular(1),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '── Devices ──',
            style: TextStyle(color: Color(0xFF00D9FF)),
          ),
          SizedBox(height: 1),
          Row(
            children: [
              Text(
                'Lights ($_lightsOn/$_totalLights)',
                style: TextStyle(color: Color(0xFF888888)),
              ),
              SizedBox(width: 1),
              Expanded(
                child: Container(
                  height: 1,
                  child: _buildProgressBar(_lightsOn / _totalLights),
                ),
              ),
              SizedBox(width: 1),
              Text(
                '${(_lightsOn * 100 / _totalLights).round()}%',
                style: TextStyle(color: _devices['lights']! ? Color(0xFF00FF88) : Color(0xFF888888)),
              ),
            ],
          ),
          _buildDeviceRow('Smart Lock', _devices['lock']! ? '🔒 LOCKED' : '🔓 UNLOCKED', _devices['lock']!),
          _buildDeviceRow('Security System', _devices['security']! ? '✓ ARMED' : '✗ DISARMED', _devices['security']!),
          _buildDeviceRow('Garage Door', _devices['garage']! ? '⬆ OPEN' : '⬇ CLOSED', _devices['garage']!),
        ],
      ),
    );
  }

  Component _buildDeviceRow(String name, String status, bool isOn) {
    return Row(
      children: [
        Text(name, style: TextStyle(color: Color(0xFF888888))),
        Spacer(),
        Text(
          status,
          style: TextStyle(
            color: isOn ? Color(0xFF00FF88) : Color(0xFFFF6B6B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Component _buildEnergyMonitor() {
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(color: Color(0xFF2A3F5F)),
        borderRadius: BorderRadius.circular(1),
      ),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '── Energy Usage ──',
            style: TextStyle(color: Color(0xFF00D9FF)),
          ),
          SizedBox(height: 1),
          Row(
            children: [
              Text(
                'Now: ${_currentPower.toStringAsFixed(1)}kW',
                style: TextStyle(color: Color(0xFF888888)),
              ),
              SizedBox(width: 1),
              Text(
                'Today: ${_todayEnergy.toStringAsFixed(1)}kWh',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ],
          ),
          SizedBox(height: 1),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  child: _buildProgressBar(_energyPercent),
                ),
              ),
              SizedBox(width: 1),
              Text(
                '${(_energyPercent * 100).round()}%',
                style: TextStyle(color: Color(0xFFFFD700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Component _buildProgressBar(double value) {
    final barWidth = 15;
    final filledWidth = (value * barWidth).round();
    final emptyWidth = barWidth - filledWidth;

    return Text(
      '[${'█' * filledWidth}${'░' * emptyWidth}]',
      style: TextStyle(color: Color(0xFF00FF88)),
    );
  }

  Component _buildFooter() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: Color(0xFF1A1F3A),
        border: BoxBorder(
          top: BorderSide(color: Color(0xFF2A3F5F), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Center(
        child: Text(
          '[1-4] Select Room  [↑↓] Navigate  [Space] Toggle Lights  [L]ock  [S]ecurity  [G]arage  [Q]uit',
          style: TextStyle(color: Color(0xFF666666)),
        ),
      ),
    );
  }
}
