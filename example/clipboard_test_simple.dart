import 'package:nocterm/nocterm.dart';

/// Simple test to demonstrate clipboard functionality
void main() async {
  print('Testing Clipboard Implementation\n');
  print('=' * 60);

  // Test 1: Basic copy/paste
  print('\n1. Testing basic copy/paste:');
  ClipboardManager.copy('Hello, World!');
  final result1 = ClipboardManager.paste();
  print('   Copied: "Hello, World!"');
  print('   Pasted: "$result1"');
  print('   ✓ ${result1 == 'Hello, World!' ? 'PASS' : 'FAIL'}');

  // Test 2: Unicode text
  print('\n2. Testing Unicode text:');
  const unicode = '你好世界 🎉 Emoji';
  ClipboardManager.copy(unicode);
  final result2 = ClipboardManager.paste();
  print('   Copied: "$unicode"');
  print('   Pasted: "$result2"');
  print('   ✓ ${result2 == unicode ? 'PASS' : 'FAIL'}');

  // Test 3: Multi-line text
  print('\n3. Testing multi-line text:');
  const multiline = 'Line 1\nLine 2\nLine 3';
  ClipboardManager.copy(multiline);
  final result3 = ClipboardManager.paste();
  print('   Copied: (3 lines)');
  print('   Pasted: (${result3?.split('\n').length ?? 0} lines)');
  print('   ✓ ${result3 == multiline ? 'PASS' : 'FAIL'}');

  // Test 4: Primary selection
  print('\n4. Testing primary selection:');
  ClipboardManager.copyToPrimary('Primary text');
  final result4 = ClipboardManager.pastePrimary();
  print('   Copied to primary: "Primary text"');
  print('   Pasted from primary: "$result4"');
  print('   ✓ ${result4 == 'Primary text' ? 'PASS' : 'FAIL'}');

  // Test 5: Clear clipboard
  print('\n5. Testing clear clipboard:');
  ClipboardManager.clear();
  final result5 = ClipboardManager.paste();
  print('   Cleared clipboard');
  print('   Content after clear: ${result5 == null ? 'null' : '"$result5"'}');
  print('   ✓ ${result5 == null ? 'PASS' : 'FAIL'}');

  // Test 6: OSC 52 sequence generation
  print('\n6. Testing OSC 52 sequence generation:');
  print('   Attempting to send OSC 52 sequence...');
  final success = Clipboard.copy('Test message');
  print('   OSC 52 write attempt: ${success ? 'succeeded' : 'failed'}');
  print('   Note: Actual clipboard integration depends on terminal support');

  // Test 7: Environment detection
  print('\n7. Testing environment detection:');
  print('   OSC 52 support detected: ${Clipboard.isSupported()}');
  print('   (This is a heuristic check based on environment variables)');

  print('\n' + '=' * 60);
  print('All internal clipboard tests completed!\n');

  print('Note: OSC 52 sequences are sent to stdout during copy operations.');
  print('In a compatible terminal (iTerm2, WezTerm, etc.), these would');
  print('integrate with your system clipboard automatically.\n');
}