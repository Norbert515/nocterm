import 'mouse_event.dart';

/// Parses mouse escape sequences from terminal input
class MouseParser {
  /// Parse SGR mouse sequence (ESC [ < button ; x ; y M/m)
  /// Returns null if not a valid mouse sequence
  static MouseEvent? parseSGR(List<int> buffer) {
    if (buffer.length < 9) return null; // Minimum: ESC [ < 0 ; 1 ; 1 M
    
    // Check for ESC [ <
    if (buffer[0] != 0x1B || buffer[1] != 0x5B || buffer[2] != 0x3C) {
      return null;
    }
    
    // Find the terminator (M or m)
    int terminatorIndex = -1;
    for (int i = 3; i < buffer.length; i++) {
      if (buffer[i] == 0x4D || buffer[i] == 0x6D) { // 'M' or 'm'
        terminatorIndex = i;
        break;
      }
    }
    
    if (terminatorIndex == -1) return null;
    
    // Parse the parameters between < and M/m
    final params = String.fromCharCodes(buffer.sublist(3, terminatorIndex));
    final parts = params.split(';');
    
    if (parts.length != 3) return null;
    
    try {
      final buttonCode = int.parse(parts[0]);
      final x = int.parse(parts[1]) - 1; // Convert to 0-based
      final y = int.parse(parts[2]) - 1; // Convert to 0-based
      final pressed = buffer[terminatorIndex] == 0x4D; // 'M' = press, 'm' = release
      
      // Decode button from SGR button code
      MouseButton? button;
      
      // In SGR mode:
      // Bits 0-1: button number (0=left, 1=middle, 2=right, 3=release/none)
      // Bit 5 (32): motion/drag flag
      // Bit 6 (64): shift for wheel (64=up, 65=down)
      
      // Check for wheel events first (64 and 65)
      if (buttonCode == 64) {
        button = MouseButton.wheelUp;
      } else if (buttonCode == 65) {
        button = MouseButton.wheelDown;
      } else {
        // For motion events (bit 5 set) with no button (bits 0-1 = 3), ignore
        final baseButton = buttonCode & 0x3;
        final isMotion = (buttonCode & 0x20) != 0; // Bit 5
        
        if (isMotion && baseButton == 3) {
          // Mouse motion without button press - ignore for now
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
            return null;
        }
      }
      
      if (button == null) return null;
      
      return MouseEvent(
        button: button,
        x: x,
        y: y,
        pressed: pressed,
      );
    } catch (e) {
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