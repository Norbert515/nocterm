import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart' hide isNotEmpty;

void main() {
  group('Comprehensive Emoji Border Tests', () {
    // ============================================
    // EMOJI CATEGORY TESTS
    // ============================================

    test('face emojis in bordered container', () async {
      await testNocterm('face emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Face Emojis:'),
                  Text('😀 😃 😄 😁 😅 😂 🤣'),
                  Text('😊 😇 🙂 😉 😌 😍 🥰'),
                  Text('😘 😗 😙 😚 😋 😛 😜'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Face Emojis:'));
        expect(tester.terminalState, containsText('😀'));
        expect(tester.terminalState, containsText('😊'));
      }, debugPrintAfterPump: true);
    });

    test('hand emojis in bordered container', () async {
      await testNocterm('hand emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.green),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Hand Emojis:'),
                  Text('👋 🤚 🖐️ ✋ 🖖 👌 🤌 🤏'),
                  Text('✌️ 🤞 🤟 🤘 🤙 👈 👉 👆'),
                  Text('👇 ☝️ 👍 👎 ✊ 👊 🤛 🤜'),
                  Text('👏 🙌 🤲 🤝 🙏'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Hand Emojis:'));
        expect(tester.terminalState, containsText('👋'));
        expect(tester.terminalState, containsText('👍'));
      }, debugPrintAfterPump: true);
    });

    test('heart emojis in bordered container', () async {
      await testNocterm('heart emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.red),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Heart Emojis:'),
                  Text('❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎'),
                  Text('💔 ❣️ 💕 💞 💓 💗 💖 💘 💝'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Heart Emojis:'));
        // Note: ❤️ may render as ❤ (without variation selector) in terminal
        expect(tester.terminalState, containsText('❤'));
        expect(tester.terminalState, containsText('💙'));
      }, debugPrintAfterPump: true);
    });

    test('animal emojis in bordered container', () async {
      await testNocterm('animal emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.yellow),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Animal Emojis:'),
                  Text('🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼'),
                  Text('🐨 🐯 🦁 🐮 🐷 🐸 🐵 🐔'),
                  Text('🐧 🐦 🦆 🦅 🦉 🦇 🐺 🐗 🐴'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Animal Emojis:'));
        expect(tester.terminalState, containsText('🐶'));
        expect(tester.terminalState, containsText('🦁'));
      }, debugPrintAfterPump: true);
    });

    test('food emojis in bordered container', () async {
      await testNocterm('food emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.magenta),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Food Emojis:'),
                  Text('🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓'),
                  Text('🫐 🍈 🍒 🍑 🥭 🍍 🥥 🥝'),
                  Text('🍅 🍆 🥑 🥦 🥬 🥒 🌶️ 🫑'),
                  Text('🌽 🥕 🧄 🧅 🥔'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Food Emojis:'));
        expect(tester.terminalState, containsText('🍎'));
        expect(tester.terminalState, containsText('🥕'));
      }, debugPrintAfterPump: true);
    });

    test('weather emojis in bordered container', () async {
      await testNocterm('weather emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Weather Emojis:'),
                  Text('☀️ 🌤️ ⛅ 🌥️ ☁️ 🌦️ 🌧️ ⛈️'),
                  Text('🌩️ 🌨️ ❄️ ☃️ ⛄ 🌬️ 💨 🌪️'),
                  Text('🌫️ 🌈 ☔'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Weather Emojis:'));
        // Note: ☀️ may render as ☀ (without variation selector) in terminal
        expect(tester.terminalState, containsText('☀'));
        expect(tester.terminalState, containsText('🌈'));
      }, debugPrintAfterPump: true);
    });

    test('object emojis in bordered container', () async {
      await testNocterm('object emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.white),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Object Emojis:'),
                  Text('💻 🖥️ 🖨️ ⌨️ 🖱️ 🖲️ 💽 💾'),
                  Text('💿 📀 📱 📲 ☎️ 📞 📟 📠'),
                  Text('📺 📻 🎙️ 🎚️ 🎛️ 🧭 ⏱️ ⏲️'),
                  Text('⏰ 🕰️'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Object Emojis:'));
        expect(tester.terminalState, containsText('💻'));
        expect(tester.terminalState, containsText('📱'));
      }, debugPrintAfterPump: true);
    });

    test('symbol emojis in bordered container', () async {
      await testNocterm('symbol emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Symbol Emojis:'),
                  Text('✨ ⭐ 🌟 ✴️ ❇️ 💫 🔥 💥'),
                  Text('💢 💦 💧 🌊 ♠️ ♥️ ♦️ ♣️'),
                  Text('🃏 🀄 🎴'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Symbol Emojis:'));
        expect(tester.terminalState, containsText('✨'));
        expect(tester.terminalState, containsText('🔥'));
      }, debugPrintAfterPump: true);
    });

    test('checkmark and status emojis in bordered container', () async {
      await testNocterm('checkmark emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.green),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Checkmark/Status Emojis:'),
                  Text('✅ ❌ ❎ ➕ ➖ ➗ ✔️ ☑️'),
                  Text('⚠️ 🚫 ⛔ 📛'),
                  Text('🔴 🟠 🟡 🟢 🔵 🟣 ⚫ ⚪ 🟤'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Checkmark/Status Emojis:'));
        expect(tester.terminalState, containsText('✅'));
        expect(tester.terminalState, containsText('🔴'));
      }, debugPrintAfterPump: true);
    });

    test('arrow emojis in bordered container', () async {
      await testNocterm('arrow emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.yellow),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Arrow Emojis:'),
                  Text('⬆️ ↗️ ➡️ ↘️ ⬇️ ↙️ ⬅️ ↖️'),
                  Text('↕️ ↔️ ↩️ ↪️ ⤴️ ⤵️ 🔃 🔄'),
                  Text('🔙 🔚 🔛 🔜 🔝'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Arrow Emojis:'));
        // Note: ⬆️ may render as ⬆ (without variation selector) in terminal
        expect(tester.terminalState, containsText('⬆'));
        expect(tester.terminalState, containsText('🔝'));
      }, debugPrintAfterPump: true);
    });

    // ============================================
    // COMPLEX EMOJI TESTS
    // ============================================

    test('flag emojis in bordered container', () async {
      await testNocterm('flag emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 45,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Flag Emojis:'),
                  Text('🇺🇸 🇬🇧 🇯🇵 🇩🇪 🇫🇷'),
                  Text('🇪🇸 🇮🇹 🇨🇳 🇰🇷 🇧🇷'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Flag Emojis:'));
      }, debugPrintAfterPump: true);
    });

    test('ZWJ family emojis in bordered container', () async {
      await testNocterm('ZWJ family emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.magenta),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('ZWJ Family Emojis:'),
                  Text('👨‍💻 👩‍💻 🧑‍💻 👨‍🔬 👩‍🔬'),
                  Text('👨‍🚀 👩‍🚀 👨‍🍳 👩‍🍳'),
                  Text('👨‍🎨 👩‍🎨 👨‍🏫 👩‍🏫'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('ZWJ Family Emojis:'));
      }, debugPrintAfterPump: true);
    });

    test('skin tone modifier emojis in bordered container', () async {
      await testNocterm('skin tone emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 45,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Skin Tone Modifiers:'),
                  Text('👋🏻 👋🏼 👋🏽 👋🏾 👋🏿'),
                  Text('👍🏻 👍🏼 👍🏽 👍🏾 👍🏿'),
                  Text('🙌🏻 🙌🏼 🙌🏽 🙌🏾 🙌🏿'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Skin Tone Modifiers:'));
      }, debugPrintAfterPump: true);
    });

    // ============================================
    // LAYOUT AND ALIGNMENT TESTS
    // ============================================

    test('emoji grid - each in own border', () async {
      await testNocterm('emoji grid border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.red),
                      ),
                      child: const Center(child: Text('😀')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.green),
                      ),
                      child: const Center(child: Text('🚀')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.blue),
                      ),
                      child: const Center(child: Text('✨')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.yellow),
                      ),
                      child: const Center(child: Text('🔥')),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.cyan),
                      ),
                      child: const Center(child: Text('💻')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.magenta),
                      ),
                      child: const Center(child: Text('🎯')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.white),
                      ),
                      child: const Center(child: Text('⭐')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.red),
                      ),
                      child: const Center(child: Text('❤️')),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.green),
                      ),
                      child: const Center(child: Text('✅')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.blue),
                      ),
                      child: const Center(child: Text('❌')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.yellow),
                      ),
                      child: const Center(child: Text('⚠️')),
                    ),
                    Container(
                      width: 6,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.cyan),
                      ),
                      child: const Center(child: Text('🔴')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        expect(tester.terminalState, containsText('😀'));
        expect(tester.terminalState, containsText('🚀'));
        expect(tester.terminalState, containsText('✨'));
      }, debugPrintAfterPump: true);
    });

    test('emoji with text alignment', () async {
      await testNocterm('emoji text alignment border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left aligned
                Container(
                  width: 35,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.red),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('✅ Success message'),
                      Text('❌ Error message'),
                      Text('⚠️ Warning message'),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                // Center aligned
                Container(
                  width: 35,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.green),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text('🎉 Congratulations! 🎉'),
                      Text('You did it! 🚀'),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                // Right aligned
                Container(
                  width: 35,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [Text('Score: 100 ⭐'), Text('Level: 5 🏆')],
                  ),
                ),
              ],
            ),
          ),
        );

        expect(tester.terminalState, containsText('✅ Success message'));
        expect(tester.terminalState, containsText('🎉 Congratulations!'));
        expect(tester.terminalState, containsText('Score: 100 ⭐'));
      }, debugPrintAfterPump: true);
    });

    test('stress test - many emojis in one container', () async {
      await testNocterm('stress test many emojis border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan, width: 2),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'STRESS TEST - Many Emojis:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(''),
                  Text('😀😃😄😁😅😂🤣😊😇🙂😉😌😍🥰😘😗😙😚😋😛😜😝'),
                  Text('👋🤚🖐️✋🖖👌🤌🤏✌️🤞🤟🤘🤙👈👉👆👇☝️👍👎✊👊'),
                  Text('❤️🧡💛💚💙💜🖤🤍🤎💔❣️💕💞💓💗💖💘💝'),
                  Text('🐶🐱🐭🐹🐰🦊🐻🐼🐨🐯🦁🐮🐷🐸🐵🐔🐧🐦🦆🦅🦉🦇'),
                  Text('🍎🍐🍊🍋🍌🍉🍇🍓🫐🍈🍒🍑🥭🍍🥥🥝🍅🍆🥑🥦🥬🥒'),
                  Text('☀️🌤️⛅🌥️☁️🌦️🌧️⛈️🌩️🌨️❄️☃️⛄🌬️💨🌪️🌫️🌈☔'),
                  Text('💻🖥️🖨️⌨️🖱️🖲️💽💾💿📀📱📲☎️📞📟📠📺📻🎙️🎚️🎛️'),
                  Text('✨⭐🌟✴️❇️💫🔥💥💢💦💧🌊♠️♥️♦️♣️🃏🀄🎴'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('STRESS TEST'));
        expect(tester.terminalState, containsText('😀'));
        expect(tester.terminalState, containsText('✨'));
      }, debugPrintAfterPump: true);
    });

    test('complex emojis in nested borders', () async {
      await testNocterm('complex emojis nested borders test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.white),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Complex Emojis Test',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 1),
                  // Flags in nested border
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.blue),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flags:'),
                        Text('🇺🇸 🇬🇧 🇯🇵 🇩🇪 🇫🇷 🇪🇸 🇮🇹 🇨🇳'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  // ZWJ in nested border
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.magenta),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ZWJ:'),
                        Text('👨‍💻 👩‍💻 🧑‍💻 👨‍🔬 👩‍🔬 👨‍🚀 👩‍🚀'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Skin tones in nested border
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.yellow),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skin Tones:'),
                        Text('👋🏻 👋🏼 👋🏽 👋🏾 👋🏿'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Complex Emojis Test'));
        expect(tester.terminalState, containsText('Flags:'));
        expect(tester.terminalState, containsText('ZWJ:'));
        expect(tester.terminalState, containsText('Skin Tones:'));
      }, debugPrintAfterPump: true);
    });

    // ============================================
    // EDGE CASE TESTS
    // ============================================

    test('single emoji per line in tight border', () async {
      await testNocterm('single emoji per line border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              padding: const EdgeInsets.all(1),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('😀'),
                  Text('🚀'),
                  Text('✨'),
                  Text('🔥'),
                  Text('💻'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('😀'));
        expect(tester.terminalState, containsText('🚀'));
      }, debugPrintAfterPump: true);
    });

    test('emoji at start, middle, and end of text', () async {
      await testNocterm('emoji position border test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 40,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.green),
              ),
              padding: const EdgeInsets.all(1),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚀 Emoji at start'),
                  Text('Text emoji 🔥 in middle'),
                  Text('Emoji at end ✨'),
                  Text('🎯 Multiple 💡 emojis ⚡ here'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('🚀 Emoji at start'));
        expect(tester.terminalState, containsText('Text emoji 🔥 in middle'));
        expect(tester.terminalState, containsText('Emoji at end ✨'));
      }, debugPrintAfterPump: true);
    });

    test('double border with emojis', () async {
      await testNocterm('double border emoji test', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 45,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.red, width: 2),
              ),
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Double Border Test:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(''),
                  Text('😀 😃 😄 😁 😅 😂 🤣'),
                  Text('✅ ❌ ⚠️ 🔴 🟢 🔵'),
                  Text('🚀 Launching! ✨'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Double Border Test:'));
        expect(tester.terminalState, containsText('😀'));
      }, debugPrintAfterPump: true);
    });

    // ============================================
    // COMPREHENSIVE VISUAL TEST
    // ============================================

    test('visual comprehensive emoji test - ALL CATEGORIES', () async {
      await testNocterm(
        'comprehensive visual emoji border test',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                width: 75,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '╔══ COMPREHENSIVE EMOJI BORDER TEST ══╗',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(''),

                    // Row 1: Faces and Hands
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.yellow),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('😀 FACES'),
                              Text('😀😃😄😁😅😂🤣😊'),
                              Text('😇🙂😉😌😍🥰😘😗'),
                            ],
                          ),
                        ),
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.cyan),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🤚 HANDS'),
                              Text('👋🤚🖐️✋🖖👌🤌🤏'),
                              Text('✌️🤞🤟🤘🤙👈👉👆'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),

                    // Row 2: Hearts and Animals
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.red),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('❤️ HEARTS'),
                              Text('❤️🧡💛💚💙💜🖤🤍'),
                              Text('💔❣️💕💞💓💗💖💘'),
                            ],
                          ),
                        ),
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.green),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🐶 ANIMALS'),
                              Text('🐶🐱🐭🐹🐰🦊🐻🐼'),
                              Text('🐨🐯🦁🐮🐷🐸🐵🐔'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),

                    // Row 3: Food and Weather
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.magenta),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🍎 FOOD'),
                              Text('🍎🍐🍊🍋🍌🍉🍇🍓'),
                              Text('🍅🍆🥑🥦🥬🥒🌶️🫑'),
                            ],
                          ),
                        ),
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.blue),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('☀️ WEATHER'),
                              Text('☀️🌤️⛅🌥️☁️🌦️🌧️⛈️'),
                              Text('🌩️🌨️❄️☃️⛄🌬️💨🌪️'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),

                    // Row 4: Objects and Symbols
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.white),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💻 OBJECTS'),
                              Text('💻🖥️🖨️⌨️🖱️🖲️💽💾'),
                              Text('💿📀📱📲☎️📞📟📠'),
                            ],
                          ),
                        ),
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.yellow),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('✨ SYMBOLS'),
                              Text('✨⭐🌟✴️❇️💫🔥💥'),
                              Text('💢💦💧🌊♠️♥️♦️♣️'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),

                    // Row 5: Checkmarks and Arrows
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.green),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('✅ STATUS'),
                              Text('✅❌❎➕➖➗✔️☑️'),
                              Text('⚠️🚫⛔📛🔴🟠🟡🟢'),
                            ],
                          ),
                        ),
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.cyan),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⬆️ ARROWS'),
                              Text('⬆️↗️➡️↘️⬇️↙️⬅️↖️'),
                              Text('↕️↔️↩️↪️⤴️⤵️🔃🔄'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),

                    // Row 6: Complex emojis
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.blue),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🇺🇸 FLAGS'),
                              Text('🇺🇸🇬🇧🇯🇵🇩🇪🇫🇷'),
                              Text('🇪🇸🇮🇹🇨🇳🇰🇷🇧🇷'),
                            ],
                          ),
                        ),
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.magenta),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('👨‍💻 ZWJ'),
                              Text('👨‍💻👩‍💻🧑‍💻👨‍🔬👩‍🔬'),
                              Text('👨‍🚀👩‍🚀👨‍🍳👩‍🍳👨‍🎨'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),

                    // Single row: Skin tones
                    Container(
                      width: 70,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.cyan),
                      ),
                      padding: const EdgeInsets.all(1),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SKIN TONE MODIFIERS'),
                          Text('Wave: 👋🏻 👋🏼 👋🏽 👋🏾 👋🏿'),
                          Text('Thumbs: 👍🏻 👍🏼 👍🏽 👍🏾 👍🏿'),
                        ],
                      ),
                    ),

                    const Text(''),
                    const Text('╚══════════════════════════════════════╝'),
                  ],
                ),
              ),
            ),
          );

          // Verify the most important sections that will definitely be visible
          expect(
            tester.terminalState,
            containsText('COMPREHENSIVE EMOJI BORDER TEST'),
          );
          expect(tester.terminalState, containsText('FACES'));
          expect(tester.terminalState, containsText('HANDS'));
          expect(tester.terminalState, containsText('HEARTS'));
          expect(tester.terminalState, containsText('ANIMALS'));
        },
        debugPrintAfterPump: true,
        size: const Size(80, 50),
      );
    });
  });
}
