import 'dart:io';
import 'package:nocterm/nocterm.dart';

// Debug log file
final _debugLog = File('gesture_debug.log');

void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  _debugLog.writeAsStringSync('[$timestamp] $message\n', mode: FileMode.append);
}

void main() {
  // Clear previous debug log
  if (_debugLog.existsSync()) {
    _debugLog.deleteSync();
  }
  _log('=== Gesture Demo Started ===');

  runApp(const GestureDemoApp());
}

class GestureDemoApp extends StatefulComponent {
  const GestureDemoApp({super.key});

  @override
  State<GestureDemoApp> createState() => _GestureDemoAppState();
}

class _GestureDemoAppState extends State<GestureDemoApp> {
  final List<String> _events = [];
  int _tapCount = 0;
  int _doubleTapCount = 0;
  int _longPressCount = 0;
  Offset? _lastTapPosition;
  // ignore: unused_field
  Offset? _lastDoubleTapPosition;
  // ignore: unused_field
  Offset? _lastLongPressPosition;
  bool _isTapDown = false;
  bool _isLongPressing = false;
  bool _isHovering = false;
  bool _isCombinedHovering = false;
  String _combinedGestureState = 'Idle';

  void _addEvent(String event) {
    _log(event);
    setState(() {
      _events.insert(0, event);
      if (_events.length > 10) _events.removeLast();
    });
  }

  @override
  Component build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 1),
          _buildGestureZones(),
          const SizedBox(height: 1),
          _buildEventLog(),
          const Spacer(),
          _buildFooter(),
        ],
      ),
    );
  }

  Component _buildHeader() {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(border: BoxBorder.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '✋ GESTURE DETECTOR DEMO',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Try different gestures in the zones below'),
        ],
      ),
    );
  }

  Component _buildGestureZones() {
    return Column(
      children: [
        // First row: Tap and Double-Tap zones
        Row(
          children: [
            const SizedBox(width: 2),
            _buildTapZone(),
            const SizedBox(width: 2),
            _buildDoubleTapZone(),
          ],
        ),
        const SizedBox(height: 1),
        // Second row: Long-Press and Hover zones
        Row(
          children: [
            const SizedBox(width: 2),
            _buildLongPressZone(),
            const SizedBox(width: 2),
            _buildHoverZone(),
          ],
        ),
        const SizedBox(height: 1),
        // Third row: Combined gestures zone
        Row(children: [const SizedBox(width: 2), _buildCombinedZone()]),
      ],
    );
  }

  Component _buildTapZone() {
    return GestureDetector(
      onTap: () {
        _addEvent('Tap detected');
        setState(() {
          _tapCount++;
        });
      },
      onTapDown: (details) {
        _addEvent(
          'Tap down at (${details.localPosition.dx.toInt()}, ${details.localPosition.dy.toInt()})',
        );
        setState(() {
          _isTapDown = true;
          _lastTapPosition = details.localPosition;
        });
      },
      onTapUp: (details) {
        _addEvent(
          'Tap up at (${details.localPosition.dx.toInt()}, ${details.localPosition.dy.toInt()})',
        );
        setState(() {
          _isTapDown = false;
        });
      },
      onTapCancel: () {
        _addEvent('Tap cancelled');
        setState(() {
          _isTapDown = false;
        });
      },
      child: Container(
        width: 22,
        height: 8,
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          color: _isTapDown ? const Color(0xFF333333) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isTapDown ? '[PRESSING]' : '  TAP ME  ',
              style: TextStyle(
                fontWeight: _isTapDown ? FontWeight.bold : null,
                color: _isTapDown ? const Color(0xFFFFFF00) : null,
              ),
            ),
            const SizedBox(height: 1),
            Text('Count: $_tapCount'),
            if (_lastTapPosition != null)
              Text(
                'Last: (${_lastTapPosition!.dx.toInt()},${_lastTapPosition!.dy.toInt()})',
              ),
          ],
        ),
      ),
    );
  }

  Component _buildDoubleTapZone() {
    return GestureDetector(
      onDoubleTap: () {
        _addEvent('Double-tap detected');
        setState(() {
          _doubleTapCount++;
        });
      },
      child: Container(
        width: 22,
        height: 8,
        decoration: BoxDecoration(border: BoxBorder.all()),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('DOUBLE TAP'),
            const SizedBox(height: 1),
            Text('Count: $_doubleTapCount'),
          ],
        ),
      ),
    );
  }

  Component _buildLongPressZone() {
    return GestureDetector(
      onLongPress: () {
        _addEvent('Long press completed');
        setState(() {
          _longPressCount++;
          _isLongPressing = false;
        });
      },
      onLongPressStart: (details) {
        _addEvent(
          'Long press started at (${details.localPosition.dx.toInt()}, ${details.localPosition.dy.toInt()})',
        );
        setState(() {
          _isLongPressing = true;
          _lastLongPressPosition = details.localPosition;
        });
      },
      onLongPressEnd: (details) {
        _addEvent(
          'Long press ended at (${details.localPosition.dx.toInt()}, ${details.localPosition.dy.toInt()})',
        );
        setState(() {
          _isLongPressing = false;
        });
      },
      child: Container(
        width: 22,
        height: 8,
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          color: _isLongPressing ? const Color(0xFF333333) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLongPressing ? '[HOLDING]' : 'LONG PRESS',
              style: TextStyle(
                fontWeight: _isLongPressing ? FontWeight.bold : null,
                color: _isLongPressing ? const Color(0xFF00FF00) : null,
              ),
            ),
            const SizedBox(height: 1),
            const Text('Hold 500ms'),
            Text('Count: $_longPressCount'),
          ],
        ),
      ),
    );
  }

  Component _buildHoverZone() {
    return MouseRegion(
      onEnter: (event) {
        _addEvent('Mouse entered hover zone');
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (event) {
        _addEvent('Mouse exited hover zone');
        setState(() {
          _isHovering = false;
        });
      },
      onHover: (event) {
        // Only log occasionally to avoid spam
        if (_events.isEmpty || !_events[0].startsWith('Hovering at')) {
          _addEvent('Hovering at (${event.x}, ${event.y})');
        }
      },
      child: Container(
        width: 22,
        height: 8,
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          color: _isHovering ? const Color(0xFF333333) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isHovering ? '[HOVERING]' : ' HOVER ME ',
              style: TextStyle(
                fontWeight: _isHovering ? FontWeight.bold : null,
                color: _isHovering ? const Color(0xFF00FFFF) : null,
              ),
            ),
            const SizedBox(height: 1),
            const Text('MouseRegion'),
          ],
        ),
      ),
    );
  }

  Component _buildCombinedZone() {
    return MouseRegion(
      onEnter: (event) {
        _addEvent('Combined: Mouse entered');
        setState(() {
          _isCombinedHovering = true;
          _combinedGestureState = 'Hovering';
        });
      },
      onExit: (event) {
        _addEvent('Combined: Mouse exited');
        setState(() {
          _isCombinedHovering = false;
          _combinedGestureState = 'Idle';
        });
      },
      child: GestureDetector(
        onTap: () {
          _addEvent('Combined: Tap');
          setState(() {
            _combinedGestureState = 'Tapped!';
          });
          // Reset state after a brief moment
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _combinedGestureState = _isCombinedHovering
                    ? 'Hovering'
                    : 'Idle';
              });
            }
          });
        },
        onDoubleTap: () {
          _addEvent('Combined: Double-tap');
          setState(() {
            _combinedGestureState = 'Double-tapped!';
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _combinedGestureState = _isCombinedHovering
                    ? 'Hovering'
                    : 'Idle';
              });
            }
          });
        },
        onLongPress: () {
          _addEvent('Combined: Long press');
          setState(() {
            _combinedGestureState = 'Long-pressed!';
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _combinedGestureState = _isCombinedHovering
                    ? 'Hovering'
                    : 'Idle';
              });
            }
          });
        },
        child: Container(
          width: 68,
          height: 5,
          decoration: BoxDecoration(
            border: BoxBorder.all(),
            color: _isCombinedHovering ? const Color(0xFF333333) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'COMBINED: All Gestures (Tap, Double-Tap, Long-Press, Hover)',
              ),
              Text(
                'State: $_combinedGestureState',
                style: TextStyle(
                  fontWeight: _combinedGestureState != 'Idle'
                      ? FontWeight.bold
                      : null,
                  color: _combinedGestureState != 'Idle'
                      ? const Color(0xFFFF00FF)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Component _buildEventLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 2),
          child: const Text(
            'Event Log (last 10 events):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          width: 94,
          height: 8,
          decoration: BoxDecoration(border: BoxBorder.all()),
          child: _events.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(1),
                  child: Text(
                    'No events yet - try interacting with the zones above!',
                  ),
                )
              : ListView(
                  children: _events.map((event) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Text('• $event'),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Component _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(left: 2, bottom: 1),
      child: const Text('Press Ctrl+C to exit'),
    );
  }
}
