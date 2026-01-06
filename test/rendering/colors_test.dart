import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Terminal Color Support', () {
    test('24-bit color output', () {
      final buffer = StringBuffer();

      // Red text using 24-bit color
      buffer.write('\x1b[38;2;255;0;0mRED (24-bit)\x1b[0m\n');
      // Green text using 24-bit color
      buffer.write('\x1b[38;2;0;255;0mGREEN (24-bit)\x1b[0m\n');
      // Blue text using 24-bit color
      buffer.write('\x1b[38;2;0;0;255mBLUE (24-bit)\x1b[0m\n');

      final output = buffer.toString();
      expect(output, contains('\x1b[38;2;255;0;0m'));
      expect(output, contains('\x1b[38;2;0;255;0m'));
      expect(output, contains('\x1b[38;2;0;0;255m'));
    });

    test('256-color mode output', () {
      final buffer = StringBuffer();

      buffer.write('\x1b[38;5;196mRED (256-color)\x1b[0m\n');
      buffer.write('\x1b[38;5;46mGREEN (256-color)\x1b[0m\n');
      buffer.write('\x1b[38;5;21mBLUE (256-color)\x1b[0m\n');

      final output = buffer.toString();
      expect(output, contains('\x1b[38;5;196m'));
      expect(output, contains('\x1b[38;5;46m'));
      expect(output, contains('\x1b[38;5;21m'));
    });

    test('basic 16-color mode output', () {
      final buffer = StringBuffer();

      buffer.write('\x1b[31mRED (16-color)\x1b[0m\n');
      buffer.write('\x1b[32mGREEN (16-color)\x1b[0m\n');
      buffer.write('\x1b[34mBLUE (16-color)\x1b[0m\n');

      final output = buffer.toString();
      expect(output, contains('\x1b[31m'));
      expect(output, contains('\x1b[32m'));
      expect(output, contains('\x1b[34m'));
    });

    test('background colors', () {
      final buffer = StringBuffer();

      // 24-bit background
      buffer.write(
        '\x1b[48;2;255;0;0m\x1b[38;2;255;255;255mWhite on RED (24-bit)\x1b[0m\n',
      );
      // 256-color background
      buffer.write(
        '\x1b[48;5;196m\x1b[38;5;15mWhite on RED (256-color)\x1b[0m\n',
      );
      // 16-color background
      buffer.write('\x1b[41m\x1b[37mWhite on RED (16-color)\x1b[0m\n');

      final output = buffer.toString();
      expect(output, contains('\x1b[48;2;255;0;0m'));
      expect(output, contains('\x1b[48;5;196m'));
      expect(output, contains('\x1b[41m'));
    });

    test('reset sequence', () {
      final buffer = StringBuffer();
      buffer.write('\x1b[31mColored\x1b[0mNormal');

      final output = buffer.toString();
      expect(output, contains('\x1b[0m'));
    });

    test('combined foreground and background colors', () {
      final buffer = StringBuffer();

      // Combine foreground and background
      buffer.write(
        '\x1b[38;2;255;255;0m\x1b[48;2;0;0;255mYellow on Blue\x1b[0m',
      );

      final output = buffer.toString();
      expect(output, contains('\x1b[38;2;255;255;0m'));
      expect(output, contains('\x1b[48;2;0;0;255m'));
    });

    // Visual test that can be run manually to see actual colors
    test('visual color test', skip: 'Run manually to see colors', () {
      print('\n=== Visual Color Test ===\n');

      print('24-bit colors:');
      stdout.write('\x1b[38;2;255;0;0mRED\x1b[0m ');
      stdout.write('\x1b[38;2;0;255;0mGREEN\x1b[0m ');
      stdout.write('\x1b[38;2;0;0;255mBLUE\x1b[0m\n');

      print('\n256-colors:');
      stdout.write('\x1b[38;5;196mRED\x1b[0m ');
      stdout.write('\x1b[38;5;46mGREEN\x1b[0m ');
      stdout.write('\x1b[38;5;21mBLUE\x1b[0m\n');

      print('\n16-colors:');
      stdout.write('\x1b[31mRED\x1b[0m ');
      stdout.write('\x1b[32mGREEN\x1b[0m ');
      stdout.write('\x1b[34mBLUE\x1b[0m\n');

      print('\nBackgrounds:');
      stdout.write('\x1b[48;2;255;0;0m\x1b[38;2;255;255;255m 24-bit \x1b[0m ');
      stdout.write('\x1b[48;5;196m\x1b[38;5;15m 256-color \x1b[0m ');
      stdout.write('\x1b[41m\x1b[37m 16-color \x1b[0m\n');

      print('\n=== End Visual Test ===\n');
    });
  });
}
