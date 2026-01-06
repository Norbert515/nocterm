import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  test('visual color test', () async {
    await testNocterm('new color palette', (tester) async {
      await tester.pumpComponent(
        Column(
          children: [
            Text(
              'Regular Colors:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.black,
                  child: Center(
                    child: Text('BLACK', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.red,
                  child: Center(child: Text('RED')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.green,
                  child: Center(child: Text('GREEN')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.yellow,
                  child: Center(child: Text('YELLOW')),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.blue,
                  child: Center(child: Text('BLUE')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.magenta,
                  child: Center(child: Text('MAGENTA')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.cyan,
                  child: Center(child: Text('CYAN')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.white,
                  child: Center(
                    child: Text('WHITE', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              'Bright Colors:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightBlack,
                  child: Center(
                    child: Text(
                      'BR BLACK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightRed,
                  child: Center(child: Text('BR RED')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightGreen,
                  child: Center(child: Text('BR GREEN')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightYellow,
                  child: Center(child: Text('BR YELLO')),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightBlue,
                  child: Center(child: Text('BR BLUE')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightMagenta,
                  child: Center(child: Text('BR MAGNT')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightCyan,
                  child: Center(child: Text('BR CYAN')),
                ),
                Container(
                  width: 10,
                  height: 2,
                  color: Colors.brightWhite,
                  child: Center(
                    child: Text(
                      'BR WHITE',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              'Sample Text Styles:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Error message', style: TextStyle(color: Colors.red)),
            Text('Success message', style: TextStyle(color: Colors.green)),
            Text('Warning message', style: TextStyle(color: Colors.yellow)),
            Text('Info message', style: TextStyle(color: Colors.blue)),
            Text('Secondary text', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }, debugPrintAfterPump: true);
  });
}
