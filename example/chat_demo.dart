import 'dart:async';
import 'dart:math';
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const ChatDemo());
}

class ChatDemo extends StatefulComponent {
  const ChatDemo({super.key});

  @override
  State<ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends State<ChatDemo> {
  final List<ChatMessage> messages = [];
  final AutoScrollController scrollController = AutoScrollController();
  final TextEditingController textController = TextEditingController();
  bool inputHasFocus = false;
  Timer? autoMessageTimer;
  int messageCounter = 1;

  // Sample auto messages for demo
  final List<String> autoMessages = [
    'Welcome to the chat demo!',
    'This demonstrates auto-scrolling behavior.',
    'Try scrolling up to read history...',
    'New messages won\'t auto-scroll when you\'re reading.',
    'Scroll back down to re-enable auto-scroll.',
    'You can also type your own messages!',
    'Press Enter to send a message.',
    'Press "a" to toggle auto messages.',
    'Press "c" to clear the chat.',
  ];
  int autoMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Add initial messages
    _addMessage(
      'System',
      'Chat demo started. Press "a" to toggle auto messages, "c" to clear.',
      isSystem: true,
    );
    _addMessage(
      'System',
      'Type a message and press Enter to send.',
      isSystem: true,
    );
  }

  @override
  void dispose() {
    autoMessageTimer?.cancel();
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  void _addMessage(String sender, String text, {bool isSystem = false}) {
    setState(() {
      messages.add(
        ChatMessage(
          sender: sender,
          text: text,
          timestamp: DateTime.now(),
          isSystem: isSystem,
        ),
      );
    });
  }

  void _sendMessage() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      _addMessage('You', text);
      textController.clear();

      // Simulate a response after a delay
      Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)), () {
        if (mounted) {
          final responses = [
            'Interesting point!',
            'I see what you mean.',
            'That makes sense.',
            'Tell me more about that.',
            'Good question!',
            'Let me think about that...',
          ];
          _addMessage('Bot', responses[Random().nextInt(responses.length)]);
        }
      });
    }
  }

  void _toggleAutoMessages() {
    if (autoMessageTimer != null) {
      autoMessageTimer!.cancel();
      autoMessageTimer = null;
      _addMessage('System', 'Auto messages stopped.', isSystem: true);
    } else {
      autoMessageTimer = Timer.periodic(Duration(seconds: 2), (_) {
        if (autoMessageIndex < autoMessages.length) {
          _addMessage('Bot', autoMessages[autoMessageIndex]);
          autoMessageIndex++;
        } else {
          _addMessage('Bot', 'Random message #${messageCounter++}');
        }
      });
      _addMessage('System', 'Auto messages started.', isSystem: true);
    }
  }

  void _clearChat() {
    setState(() {
      messages.clear();
      autoMessageIndex = 0;
      messageCounter = 1;
    });
    _addMessage('System', 'Chat cleared.', isSystem: true);
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.keyA && !inputHasFocus) {
      _toggleAutoMessages();
      return true;
    } else if (event.logicalKey == LogicalKey.keyC && !inputHasFocus) {
      _clearChat();
      return true;
    } else if (event.logicalKey == LogicalKey.escape) {
      setState(() {
        inputHasFocus = false;
      });
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: Color.fromRGB(0, 50, 100),
              border: BoxBorder.all(color: Colors.cyan),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat Demo',
                  style: TextStyle(
                    color: Colors.brightWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Messages: ${messages.length} | Auto-scroll: ${scrollController.isAutoScrollEnabled ? "ON" : "OFF"}',
                  style: TextStyle(color: Colors.yellow),
                ),
              ],
            ),
          ),

          // Chat messages area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet. Start typing or press "a" for auto messages.',
                        style: TextStyle(color: Colors.gray),
                      ),
                    )
                  : Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.all(1),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _MessageWidget(message: message);
                        },
                      ),
                    ),
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder(top: BorderSide(color: Colors.blue)),
              color: Color.fromRGB(20, 20, 40),
            ),
            child: Row(
              children: [
                Text('> ', style: TextStyle(color: Colors.green)),
                Expanded(
                  child: TextField(
                    controller: textController,
                    style: TextStyle(color: Colors.white),
                    placeholder: 'Type a message...',
                    onSubmitted: (_) => _sendMessage(),
                    onFocusChange: (focused) {
                      setState(() {
                        inputHasFocus = focused;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Status bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: Color.fromRGB(0, 20, 40),
              border: BoxBorder(top: BorderSide(color: Colors.cyan)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '[a] Toggle auto messages | ',
                  style: TextStyle(color: Colors.gray),
                ),
                Text('[c] Clear chat | ', style: TextStyle(color: Colors.gray)),
                Text('[↑↓] Scroll | ', style: TextStyle(color: Colors.gray)),
                Text('[Enter] Send', style: TextStyle(color: Colors.gray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageWidget extends StatelessComponent {
  final ChatMessage message;

  const _MessageWidget({required this.message});

  @override
  Component build(BuildContext context) {
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}:'
        '${message.timestamp.second.toString().padLeft(2, '0')}';

    Color senderColor;
    if (message.isSystem) {
      senderColor = Colors.yellow;
    } else if (message.sender == 'You') {
      senderColor = Colors.green;
    } else {
      senderColor = Colors.cyan;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      decoration: BoxDecoration(
        border: BoxBorder(bottom: BorderSide(color: Colors.gray)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[$timeStr]', style: TextStyle(color: Colors.gray)),
          SizedBox(width: 1),
          Text(
            '${message.sender}:',
            style: TextStyle(
              color: senderColor,
              fontWeight: message.isSystem
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          SizedBox(width: 1),
          Expanded(
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isSystem ? Colors.yellow : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });
}
