import 'dart:io';
import 'package:nocterm/nocterm.dart';

/// Debug clipboard behavior
void main() async {
  print('Clipboard Debug Tool\n');
  print('=' * 60);

  // Show diagnostics
  print('\n${Clipboard.getDiagnostics()}');
  print('=' * 60);

  // Test 1: Check what's currently in internal buffer
  print('\n1. Current internal clipboard state:');
  final current = ClipboardManager.paste();
  print('   Internal buffer: ${current == null ? 'null/empty' : '"$current"'}');

  // Test 2: Try to read from system clipboard using pbpaste (macOS)
  if (Platform.isMacOS) {
    print('\n2. System clipboard (via pbpaste):');
    try {
      final result = await Process.run('pbpaste', []);
      if (result.exitCode == 0) {
        final systemClipboard = result.stdout.toString();
        print('   System clipboard: "${systemClipboard.trim()}"');
        print('   Length: ${systemClipboard.length} characters');
      } else {
        print('   Could not read system clipboard');
      }
    } catch (e) {
      print('   Error reading system clipboard: $e');
    }
  }

  // Test 3: Copy something and show the OSC 52 sequence
  print('\n3. Copying "Test Message" to clipboard:');
  print('   Sending OSC 52 sequence...');
  final success = Clipboard.copy('Test Message');
  print('   Result: ${success ? 'sent' : 'failed'}');

  // Check internal buffer
  final internalAfter = ClipboardManager.paste();
  print('   Internal buffer after copy: ${internalAfter == null ? 'null/empty' : '"$internalAfter"'}');

  // Check system clipboard again
  if (Platform.isMacOS) {
    print('\n4. System clipboard after our copy (via pbpaste):');
    await Future.delayed(Duration(milliseconds: 100)); // Give terminal time to process
    try {
      final result = await Process.run('pbpaste', []);
      if (result.exitCode == 0) {
        final systemClipboard = result.stdout.toString();
        print('   System clipboard: "${systemClipboard.trim()}"');
      }
    } catch (e) {
      print('   Error: $e');
    }
  }

  // Test 4: Use ClipboardManager (which has internal buffer)
  print('\n5. Using ClipboardManager.copy():');
  ClipboardManager.copy('ClipboardManager Test');
  final managerResult = ClipboardManager.paste();
  print('   Copied via ClipboardManager: "ClipboardManager Test"');
  print('   Pasted via ClipboardManager: "$managerResult"');
  print('   Match: ${managerResult == 'ClipboardManager Test'}');

  print('\n' + '=' * 60);
  print('Debug complete!\n');
  print('NOTE: OSC 52 integration depends on:');
  print('1. Your terminal emulator supporting OSC 52');
  print('2. Terminal configuration allowing clipboard access');
  print('3. No SSH or remote session blocking OSC 52');
  print('\nThe internal buffer (ClipboardManager) always works,');
  print('but system clipboard integration requires terminal support.\n');
}