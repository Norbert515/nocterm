import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const SubmitDemo());
}

class SubmitDemo extends StatefulComponent {
  const SubmitDemo();

  @override
  State createState() => _SubmitDemoState();
}

class _SubmitDemoState extends State<SubmitDemo> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _submittedValues = [];
  String _currentInput = '';
  bool _isFocused = true;

  void _handleSubmit() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _submittedValues.add(_controller.text);
        _currentInput = _controller.text;
        _controller.clear();
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return Container(
      width: 60,
      height: 20,
      decoration: BoxDecoration(border: BoxBorder.all(color: Colors.blue)),
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Field Submit Demo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          SizedBox(height: 1),
          Text('Type text and press Enter to submit:'),
          SizedBox(height: 1),
          Container(
            width: 56,
            child: TextField(
              focused: _isFocused,
              onFocusChange: (focused) {
                setState(() {
                  _isFocused = focused;
                });
              },
              controller: _controller,
              placeholder: 'Type here and press Enter...',
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          SizedBox(height: 1),
          if (_currentInput.isNotEmpty)
            Text(
              'Last submitted: "$_currentInput"',
              style: TextStyle(color: Colors.green),
            ),
          SizedBox(height: 1),
          Text(
            'History (${_submittedValues.length} items):',
            style: TextStyle(color: Colors.yellow),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.gray),
              ),
              padding: EdgeInsets.all(1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    int i = _submittedValues.length - 1;
                    i >= 0 && i >= _submittedValues.length - 5;
                    i--
                  )
                    Text(
                      '${i + 1}. ${_submittedValues[i]}',
                      style: TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1),
          Text('Press Ctrl+C to exit', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
