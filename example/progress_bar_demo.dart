import 'dart:async';
import 'package:nocterm/nocterm.dart';

class ProgressBarDemo extends StatefulComponent {
  @override
  State<ProgressBarDemo> createState() => _ProgressBarDemoState();
}

class _ProgressBarDemoState extends State<ProgressBarDemo> {
  double downloadProgress = 0.0;
  double uploadProgress = 0.0;
  double processingProgress = 0.0;
  bool isIndeterminate = false;
  Timer? _timer;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        // Animate download progress
        if (downloadProgress < 1.0) {
          downloadProgress += 0.02;
        }

        // Animate upload progress (slower)
        if (uploadProgress < 1.0) {
          uploadProgress += 0.01;
        }

        // Animate processing progress (variable speed)
        if (processingProgress < 1.0) {
          processingProgress += 0.015;
        } else {
          // Reset all when done
          downloadProgress = 0.0;
          uploadProgress = 0.0;
          processingProgress = 0.0;
        }
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
    return Container(
      padding: EdgeInsets.all(2),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Bar Demo',
                style: TextStyle(
                  color: Colors.cyan,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 2),

              // Basic progress bars
              Text(
                'Basic Progress Bars:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),

              Text('Download: ${(downloadProgress * 100).toInt()}%'),
              SizedBox(
                width: 50,
                height: 1,
                child: ProgressBar(
                  value: downloadProgress,
                  valueColor: Colors.green,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),

              Text('Upload: ${(uploadProgress * 100).toInt()}%'),
              SizedBox(
                width: 50,
                height: 1,
                child: ProgressBar(
                  value: uploadProgress,
                  valueColor: Colors.blue,
                  backgroundColor: Colors.grey,
                  fillCharacter: '=',
                  emptyCharacter: '-',
                ),
              ),
              SizedBox(height: 2),

              // Progress bar with border and percentage
              Text(
                'With Border and Percentage:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 50,
                height: 3,
                child: ProgressBar(
                  value: processingProgress,
                  showPercentage: true,
                  borderStyle: ProgressBarBorderStyle.rounded,
                  valueColor: Colors.magenta,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 2),

              // Progress bar with custom label
              Text(
                'With Custom Label:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 50,
                height: 3,
                child: ProgressBar(
                  value: processingProgress * 0.7,
                  label: 'Processing...',
                  borderStyle: ProgressBarBorderStyle.single,
                  valueColor: Colors.cyan,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 2),

              // Indeterminate progress
              Text(
                'Indeterminate Progress:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 50,
                height: 1,
                child: ProgressBar(
                  indeterminate: true,
                  valueColor: Colors.yellow,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 50,
                height: 3,
                child: ProgressBar(
                  indeterminate: true,
                  borderStyle: ProgressBarBorderStyle.double,
                  valueColor: Colors.red,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 2),

              // Different styles showcase
              Text('Different Styles:', style: TextStyle(color: Colors.yellow)),
              SizedBox(height: 1),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASCII:', style: TextStyle(color: Colors.white)),
                        SizedBox(
                          height: 3,
                          child: ProgressBar(
                            value: 0.75,
                            borderStyle: ProgressBarBorderStyle.ascii,
                            valueColor: Colors.green,
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bold:', style: TextStyle(color: Colors.white)),
                        SizedBox(
                          height: 3,
                          child: ProgressBar(
                            value: 0.75,
                            borderStyle: ProgressBarBorderStyle.bold,
                            valueColor: Colors.cyan,
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),

              // Custom characters showcase
              Text(
                'Custom Characters:',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 1),

              Text('Blocks: ▓░'),
              SizedBox(
                width: 50,
                height: 1,
                child: ProgressBar(
                  value: 0.6,
                  fillCharacter: '▓',
                  emptyCharacter: '░',
                  valueColor: Colors.white,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),

              Text('Dots: ●○'),
              SizedBox(
                width: 50,
                height: 1,
                child: ProgressBar(
                  value: 0.4,
                  fillCharacter: '●',
                  emptyCharacter: '○',
                  valueColor: Colors.red,
                  backgroundColor: Colors.grey,
                ),
              ),

              SizedBox(height: 2),
              Text(
                'Press Ctrl+C to exit',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(ProgressBarDemo());
}
