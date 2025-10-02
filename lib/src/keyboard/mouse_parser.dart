import 'package:nocterm/nocterm.dart' show TerminalBinding;
import 'package:nocterm/src/keyboard/input_parser.dart';
import 'package:win32/win32.dart';

import 'mouse_event.dart';

/// Parses mouse escape sequences from terminal input
class MouseParser {
  /// Parse SGR mouse sequence (ESC [ < button ; x ; y M/m)
  /// Returns null if not a valid mouse sequence
  static MouseEvent? parseSGR(List<int> buffer, int terminatorIndex) {

    TerminalBinding.instance.logSink?.writeln('MouseParser.parseSGR() terminatorIndex=$terminatorIndex buffer=${dumpList(buffer.sublist(0,terminatorIndex+1))}');

    int mouseSequenceLength = terminatorIndex + 1;
    if (mouseSequenceLength<9 || buffer.length < mouseSequenceLength) return null; // Minimum: ESC [ < 0 ; 1 ; 1 M
    
    // Check for ESC [ <  (0x1B = ESC, 0x5B = [, 0x3C = '<', 0x4D = 'M', 0x6D = 'm')
    if (buffer[0] != 0x1B || buffer[1] != 0x5B || buffer[2] != 0x3C) {
      return null;
    }
    if(buffer[3]==0x33 && buffer[4]==0x35) { // `ESC [ < 35`  THIS IS button code==NONE
      TerminalBinding.instance.logSink?.writeln('MouseParser.parseSGR() Ignoring mouse move - button code of NONE');
      return null;
    }


    final terminatorChar =String.fromCharCodes(buffer.sublist(terminatorIndex, terminatorIndex+1));
    TerminalBinding.instance.logSink?.writeln('parseSGR terminatorChar: $terminatorChar terminatorIndex: $terminatorIndex');
    

    // Find the terminator (M or m)
    //int terminatorIndex = -1;
    //for (int i = 3; i < mouseSequenceLength; i++) {
    //  if (buffer[i] == 0x4D || buffer[i] == 0x6D) { // 'M' or 'm'
    //    terminatorIndex = i;
    //    break;
    //  }
    //}
    
    //if (terminatorIndex == -1) return null;
    
    // Parse the parameters between < and M/m
    final params = String.fromCharCodes(buffer.sublist(3, terminatorIndex));
    final parts = params.split(';');

    TerminalBinding.instance.logSink?.writeln('params: $params parts: $parts ');

    if (parts.length != 3) return null;
    
    try {
      final buttonCode = int.parse(parts[0]);
      final x = int.parse(parts[1]) - 1; // Convert to 0-based
      final y = int.parse(parts[2]) - 1; // Convert to 0-based
      final pressed = buffer[terminatorIndex] == 0x4D; // 'M' = press, 'm' = release

      TerminalBinding.instance.logSink?.writeln('buttonCode: ${dumpBinary(buttonCode)} col x: $x row y: $y pressed: $pressed');

      // Decode button from SGR button code
      MouseButton? button;
      
      // In SGR mode:
      // Bits 0-1: button number (0=left, 1=middle, 2=right, 3=release/none)
      // Bit 5 (32 (0x20)): motion/drag flag
      // Bit 6 (64 (0x40)): shift for wheel (64=up, 65=down)
      
      // Check for wheel events first (64 and 65)
      if (buttonCode == 0x40) { // 64 (0x40) = 0b1000000 (bit 6 set)
        button = MouseButton.wheelUp;
      } else if (buttonCode == 0x41) { // 65 (0x41) = 0b1000001 (bits 6 and 0 set)
        button = MouseButton.wheelDown;
      } else {
        // For motion events (bit 5 set) with no button (bits 0-1 = 3), ignore
        final baseButton = buttonCode & 0x03;
        final isMotion = (buttonCode & 0x20) != 0; // Bit 5

        TerminalBinding.instance.logSink?.writeln('baseButton: $baseButton isMotion: $isMotion');

        if (isMotion && baseButton == 3) {
          // Mouse motion without button press - ignore for now
          TerminalBinding.instance.logSink?.writeln('MouseMotion without button press - ignoring');
          return null;
        }
        
        // Regular button events
        switch (baseButton) {
          case 0:
            button = MouseButton.left;
            break;
          case 1:
            button = MouseButton.middle;
            break;
          case 2:
            button = MouseButton.right;
            break;
          case 3:
            // Release or no button
            TerminalBinding.instance.logSink?.writeln('MouseMotion RELEASE or NO button - ignoring');
            return null;
        }
      }

      if (button == null) {
        TerminalBinding.instance.logSink?.writeln('MouseMotion button==null - ignoring');
        return null;
      }

      TerminalBinding.instance.logSink?.writeln('Returning MouseEvent: button=$button x=$x y=$y pressed=$pressed ');

      return MouseEvent(
        button: button,
        x: x,
        y: y,
        pressed: pressed,
      );
    } catch (e) {
      TerminalBinding.instance.logSink?.writeln('MouseParser.parseSGR() Exception parsing SGR mouse event: $e');
      return null;
    }
  }
  
  /// Parse X10 mouse sequence (ESC [ M button x y)
  /// Legacy format, still used by some terminals
  static MouseEvent? parseX10(List<int> buffer) {
    if (buffer.length < 6) return null;
    
    // Check for ESC [ M
    if (buffer[0] != 0x1B || buffer[1] != 0x5B || buffer[2] != 0x4D) {
      return null;
    }
    
    if (buffer.length != 6) return null;
    
    // X10 encoding: button and coordinates are offset by 32
    final buttonByte = buffer[3] - 32;
    final x = buffer[4] - 33; // -32 for encoding, -1 for 0-based
    final y = buffer[5] - 33;
    
    // Validate coordinates
    if (x < 0 || y < 0) return null;
    
    // Decode button
    MouseButton? button;
    bool pressed = true;
    
    // In X10 mode:
    // Bits 0-1: button number (0=left, 1=middle, 2=right, 3=release)
    // Bit 6: wheel flag
    final buttonNum = buttonByte & 0x03;
    final wheelFlag = buttonByte & 0x40;
    
    if (wheelFlag != 0) {
      // Wheel events (always "pressed")
      if (buttonNum == 0) {
        button = MouseButton.wheelUp;
      } else if (buttonNum == 1) {
        button = MouseButton.wheelDown;
      }
    } else {
      // Regular buttons
      if (buttonNum == 3) {
        // Release event - we don't know which button, default to left
        button = MouseButton.left;
        pressed = false;
      } else {
        pressed = true;
        switch (buttonNum) {
          case 0:
            button = MouseButton.left;
            break;
          case 1:
            button = MouseButton.middle;
            break;
          case 2:
            button = MouseButton.right;
            break;
        }
      }
    }
    
    if (button == null) return null;
    
    return MouseEvent(
      button: button,
      x: x,
      y: y,
      pressed: pressed,
    );
  }
}