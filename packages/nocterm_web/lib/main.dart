import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart' as xterm;
import 'package:xterm/ui.dart' as xterm_flutter;
import 'package:nocterm/nocterm.dart' as nocterm;
import 'package:nocterm/nocterm.dart' show WebBackend;
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

void main() {
  runApp(const NoctermWebApp());
}

class NoctermWebApp extends StatelessWidget {
  const NoctermWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nocterm Web Terminal',
      theme: ThemeData.dark(),
      home: const TerminalPage(),
    );
  }
}

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late xterm.Terminal terminal;
  StreamSubscription? _outputSubscription;

  @override
  void initState() {
    super.initState();

    // Create xterm terminal
    terminal = xterm.Terminal(maxLines: 1000);

    // Defer initialization until after first frame
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _initializeHost();
    });
  }

  void _initializeHost() {
    // Initialize the JS bridge (must be done before loading guest app)
    WebBackend.initializeHost();

    // Set initial size from xterm
    WebBackend.setSize(
      nocterm.Size(
        terminal.viewWidth.toDouble(),
        terminal.viewHeight.toDouble(),
      ),
    );

    // Clear terminal and scroll to top before loading app
    terminal.write('\x1b[2J'); // Clear entire screen
    terminal.write('\x1b[H'); // Move cursor to home (top-left)

    // Connect WebBackend output to xterm
    _outputSubscription = WebBackend.outputStream.listen((data) {
      terminal.write(data);
    });

    // Connect xterm input to WebBackend
    terminal.onOutput = (data) {
      WebBackend.sendInputString(data);
    };

    // Connect xterm resize to WebBackend
    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      WebBackend.setSize(nocterm.Size(width.toDouble(), height.toDouble()));
    };

    // Load the nocterm app
    _loadNoctermApp();
  }

  Future<void> _loadNoctermApp() async {
    try {
      // The compiled app JS should be placed in web/app.js
      // or loaded from a URL parameter
      final appUrl = _getAppUrl();

      await _injectScript(appUrl);

      // Give the guest app a moment to initialize, then force size update
      await Future.delayed(const Duration(milliseconds: 100));

      // Force a size update now that app is connected and xterm is rendered
      if (WebBackend.isAppConnected) {
        WebBackend.setSize(
          nocterm.Size(
            terminal.viewWidth.toDouble(),
            terminal.viewHeight.toDouble(),
          ),
        );
      }
    } catch (e) {
      // Show error in terminal
      terminal.write('\x1b[31mError: Failed to load app: $e\x1b[0m\r\n');
    }
  }

  String _getAppUrl() {
    // Check URL parameter first: ?app=https://example.com/myapp.js
    final uri = Uri.base;
    final appParam = uri.queryParameters['app'];
    if (appParam != null && appParam.isNotEmpty) {
      return appParam;
    }

    // Default to app.js in the same directory
    return 'app.js';
  }

  Future<void> _injectScript(String url) async {
    final completer = Completer<void>();

    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.src = url;
    script.type = 'application/javascript';

    script.onload = ((web.Event event) {
      completer.complete();
    }).toJS;

    script.onerror = ((web.Event event) {
      completer.completeError('Failed to load script: $url');
    }).toJS;

    web.document.head?.appendChild(script);

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: xterm_flutter.TerminalView(
          terminal,
          textStyle: xterm_flutter.TerminalStyle.fromTextStyle(
            GoogleFonts.jetBrainsMono().copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    WebBackend.requestShutdown();
    super.dispose();
  }
}
