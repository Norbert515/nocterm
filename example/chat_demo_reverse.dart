import 'package:nocterm/nocterm.dart';

/// Demo showing AutoScrollController working correctly with reverse ListView
/// for a chat-like interface.
void main() async {
  await runApp(ChatDemoReverse());
}

class ChatDemoReverse extends StatefulComponent {
  const ChatDemoReverse({super.key});

  @override
  State<ChatDemoReverse> createState() => _ChatDemoReverseState();
}

class _ChatDemoReverseState extends State<ChatDemoReverse> {
  final messages = <String>[];
  final textController = TextEditingController();
  // AutoScrollController automatically detects reverse from ListView
  final scrollController = AutoScrollController();

  @override
  void initState() {
    super.initState();
    // Add some initial messages
    for (int i = 1; i <= 200; i++) {
      messages.add('Welcome message $i');
    }
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (textController.text.isNotEmpty) {
      setState(() {
        messages.add('You: ${textController.text}');
        textController.clear();
      });

      // Simulate bot response after a moment
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            messages.add('Bot: Thanks for your message!');
          });
        }
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          shutdownApp();
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.blue),
        ),
        padding: EdgeInsets.all(1),
        child: Column(
          children: [
            // Title
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                child: Text(
                  'Chat Demo with Reverse ListView',
                  style: TextStyle(
                    color: Colors.brightWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Messages area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                ),
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    reverse: true, // Makes the list start from bottom
                    controller: scrollController,
                    padding: EdgeInsets.all(1),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Reverse the index to show newest messages at bottom
                      final messageIndex = messages.length - 1 - index;
                      final message = messages[messageIndex];
                      final isUser = message.startsWith('You:');

                      return Container(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        margin: EdgeInsets.only(bottom: 1),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.green : Colors.cyan,
                          ),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.brightWhite,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Status line
            Container(
              padding: EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Text(
                    'Auto-scroll: ',
                    style: TextStyle(color: Colors.gray),
                  ),
                  Text(
                    scrollController.isAutoScrollEnabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: scrollController.isAutoScrollEnabled ? Colors.green : Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '  |  Messages: ${messages.length}',
                    style: TextStyle(color: Colors.gray),
                  ),
                ],
              ),
            ),

            // Input area
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 1),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                    ),
                    child: Text(
                      'ENTER',
                      style: TextStyle(
                        color: Colors.brightWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Container(
              padding: EdgeInsets.only(top: 1),
              child: Text(
                'Scroll up to see history (auto-scroll will turn OFF) | ESC to exit',
                style: TextStyle(color: Colors.gray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
