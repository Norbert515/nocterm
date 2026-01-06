import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Curves', () {
    group('linear', () {
      test('returns t unchanged', () {
        expect(Curves.linear.transform(0.0), 0.0);
        expect(Curves.linear.transform(0.25), 0.25);
        expect(Curves.linear.transform(0.5), 0.5);
        expect(Curves.linear.transform(0.75), 0.75);
        expect(Curves.linear.transform(1.0), 1.0);
      });
    });

    group('ease', () {
      test('returns 0 at t=0', () {
        expect(Curves.ease.transform(0.0), 0.0);
      });

      test('returns 1 at t=1', () {
        expect(Curves.ease.transform(1.0), 1.0);
      });

      test('returns intermediate value at t=0.5', () {
        final value = Curves.ease.transform(0.5);
        expect(value, greaterThan(0.0));
        expect(value, lessThan(1.0));
      });

      test('starts slow and ends slow', () {
        // Ease curve should have slower rate of change at the ends
        final earlyDelta =
            Curves.ease.transform(0.1) - Curves.ease.transform(0.0);
        final midDelta =
            Curves.ease.transform(0.55) - Curves.ease.transform(0.45);
        final lateDelta =
            Curves.ease.transform(1.0) - Curves.ease.transform(0.9);

        // Middle should change faster than the ends
        expect(midDelta, greaterThan(earlyDelta));
        expect(midDelta, greaterThan(lateDelta));
      });
    });

    group('easeIn', () {
      test('returns 0 at t=0', () {
        expect(Curves.easeIn.transform(0.0), 0.0);
      });

      test('returns 1 at t=1', () {
        expect(Curves.easeIn.transform(1.0), 1.0);
      });

      test('returns intermediate value at t=0.5', () {
        final value = Curves.easeIn.transform(0.5);
        expect(value, greaterThan(0.0));
        expect(value, lessThan(1.0));
      });

      test('starts slow (value at 0.5 is less than 0.5)', () {
        // EaseIn starts slow, so at t=0.5 the value should be less than 0.5
        final value = Curves.easeIn.transform(0.5);
        expect(value, lessThan(0.5));
      });
    });

    group('easeOut', () {
      test('returns 0 at t=0', () {
        expect(Curves.easeOut.transform(0.0), 0.0);
      });

      test('returns 1 at t=1', () {
        expect(Curves.easeOut.transform(1.0), 1.0);
      });

      test('returns intermediate value at t=0.5', () {
        final value = Curves.easeOut.transform(0.5);
        expect(value, greaterThan(0.0));
        expect(value, lessThan(1.0));
      });

      test('ends slow (value at 0.5 is greater than 0.5)', () {
        // EaseOut ends slow, so at t=0.5 the value should be greater than 0.5
        final value = Curves.easeOut.transform(0.5);
        expect(value, greaterThan(0.5));
      });
    });

    group('easeInOut', () {
      test('returns 0 at t=0', () {
        expect(Curves.easeInOut.transform(0.0), 0.0);
      });

      test('returns 1 at t=1', () {
        expect(Curves.easeInOut.transform(1.0), 1.0);
      });

      test('returns intermediate value at t=0.5', () {
        final value = Curves.easeInOut.transform(0.5);
        expect(value, greaterThan(0.0));
        expect(value, lessThan(1.0));
      });

      test('is symmetric around t=0.5', () {
        // easeInOut should be symmetric
        final value25 = Curves.easeInOut.transform(0.25);
        final value75 = Curves.easeInOut.transform(0.75);
        // value25 + value75 should approximately equal 1.0
        expect(value25 + value75, closeTo(1.0, 0.05));
      });
    });

    group('decelerate', () {
      test('returns 0 at t=0', () {
        expect(Curves.decelerate.transform(0.0), 0.0);
      });

      test('returns 1 at t=1', () {
        expect(Curves.decelerate.transform(1.0), 1.0);
      });

      test('decelerates over time', () {
        // Decelerate should have faster change early and slower later
        final earlyDelta =
            Curves.decelerate.transform(0.1) - Curves.decelerate.transform(0.0);
        final lateDelta =
            Curves.decelerate.transform(1.0) - Curves.decelerate.transform(0.9);
        expect(earlyDelta, greaterThan(lateDelta));
      });
    });

    group('bounceIn', () {
      test('returns 0 at t=0', () {
        expect(Curves.bounceIn.transform(0.0), closeTo(0.0, 0.001));
      });

      test('returns 1 at t=1', () {
        expect(Curves.bounceIn.transform(1.0), closeTo(1.0, 0.001));
      });

      test('has characteristic bouncing shape', () {
        // BounceIn should start slow and accelerate with bounces
        final early = Curves.bounceIn.transform(0.2);
        final late = Curves.bounceIn.transform(0.8);
        // Values should generally increase as we approach 1.0
        expect(late, greaterThan(early));
      });
    });

    group('bounceOut', () {
      test('returns 0 at t=0', () {
        expect(Curves.bounceOut.transform(0.0), closeTo(0.0, 0.001));
      });

      test('returns 1 at t=1', () {
        expect(Curves.bounceOut.transform(1.0), closeTo(1.0, 0.001));
      });
    });

    group('bounceInOut', () {
      test('returns 0 at t=0', () {
        expect(Curves.bounceInOut.transform(0.0), closeTo(0.0, 0.001));
      });

      test('returns 1 at t=1', () {
        expect(Curves.bounceInOut.transform(1.0), closeTo(1.0, 0.001));
      });

      test('returns approximately 0.5 at t=0.5', () {
        expect(Curves.bounceInOut.transform(0.5), closeTo(0.5, 0.001));
      });
    });

    group('elasticIn', () {
      test('returns 0 at t=0', () {
        expect(Curves.elasticIn.transform(0.0), closeTo(0.0, 0.01));
      });

      test('returns 1 at t=1', () {
        expect(Curves.elasticIn.transform(1.0), closeTo(1.0, 0.01));
      });

      test('oscillates (has negative values)', () {
        var hasNegativeValue = false;
        for (var t = 0.0; t <= 1.0; t += 0.01) {
          if (Curves.elasticIn.transform(t) < -0.01) {
            hasNegativeValue = true;
            break;
          }
        }
        expect(hasNegativeValue, isTrue);
      });
    });

    group('elasticOut', () {
      test('returns 0 at t=0', () {
        expect(Curves.elasticOut.transform(0.0), closeTo(0.0, 0.01));
      });

      test('returns 1 at t=1', () {
        expect(Curves.elasticOut.transform(1.0), closeTo(1.0, 0.01));
      });

      test('oscillates (has values greater than 1)', () {
        var hasOvershoot = false;
        for (var t = 0.0; t <= 1.0; t += 0.01) {
          if (Curves.elasticOut.transform(t) > 1.01) {
            hasOvershoot = true;
            break;
          }
        }
        expect(hasOvershoot, isTrue);
      });
    });

    group('elasticInOut', () {
      test('returns 0 at t=0', () {
        expect(Curves.elasticInOut.transform(0.0), closeTo(0.0, 0.01));
      });

      test('returns 1 at t=1', () {
        expect(Curves.elasticInOut.transform(1.0), closeTo(1.0, 0.01));
      });
    });
  });

  group('Cubic', () {
    test('linear cubic returns t unchanged', () {
      // A cubic with control points at (0,0) and (1,1) should be linear
      const linearCubic = Cubic(0.0, 0.0, 1.0, 1.0);
      expect(linearCubic.transform(0.0), 0.0);
      expect(linearCubic.transform(0.5), closeTo(0.5, 0.01));
      expect(linearCubic.transform(1.0), 1.0);
    });

    test('handles edge cases', () {
      const cubic = Cubic(0.25, 0.1, 0.25, 1.0);
      expect(cubic.transform(0.0), 0.0);
      expect(cubic.transform(1.0), 1.0);
    });

    test('returns intermediate values', () {
      const cubic = Cubic(0.42, 0.0, 0.58, 1.0); // easeInOut
      final value = cubic.transform(0.5);
      expect(value, greaterThan(0.0));
      expect(value, lessThan(1.0));
    });

    test('toString returns readable representation', () {
      const cubic = Cubic(0.42, 0.0, 0.58, 1.0);
      expect(cubic.toString(), contains('Cubic'));
      expect(cubic.toString(), contains('0.42'));
    });
  });

  group('FlippedCurve', () {
    test('flipped linear curve reverses direction', () {
      final flipped = Curves.linear.flipped;
      // FlippedCurve.transform(t) = 1.0 - curve.transform(1.0 - t)
      // For linear: flipped(0) = 1 - linear(1) = 1 - 1 = 0
      // For linear: flipped(1) = 1 - linear(0) = 1 - 0 = 1
      // For linear: flipped(0.5) = 1 - linear(0.5) = 1 - 0.5 = 0.5
      expect(flipped.transform(0.0), closeTo(0.0, 0.001));
      expect(flipped.transform(0.5), closeTo(0.5, 0.001));
      expect(flipped.transform(1.0), closeTo(1.0, 0.001));
    });

    test('reverses easeIn to create easeOut-like behavior', () {
      final flippedEaseIn = Curves.easeIn.flipped;
      // Original easeIn at 0.5 is < 0.5
      // flipped(0.5) = 1 - easeIn(1 - 0.5) = 1 - easeIn(0.5)
      // Since easeIn(0.5) < 0.5, then flipped(0.5) > 0.5
      final value = flippedEaseIn.transform(0.5);
      expect(value, greaterThan(0.5));
    });

    test('double flip returns to original', () {
      final doubleFlipped = Curves.ease.flipped.flipped;
      expect(doubleFlipped.transform(0.0), closeTo(0.0, 0.001));
      expect(
        doubleFlipped.transform(0.5),
        closeTo(Curves.ease.transform(0.5), 0.01),
      );
      expect(doubleFlipped.transform(1.0), closeTo(1.0, 0.001));
    });

    test('toString indicates flipped', () {
      final flipped = Curves.linear.flipped;
      expect(flipped.toString().toLowerCase(), contains('flipped'));
    });
  });

  group('All standard curves', () {
    final curves = <String, Curve>{
      'linear': Curves.linear,
      'ease': Curves.ease,
      'easeIn': Curves.easeIn,
      'easeOut': Curves.easeOut,
      'easeInOut': Curves.easeInOut,
      'easeInSine': Curves.easeInSine,
      'easeOutSine': Curves.easeOutSine,
      'easeInOutSine': Curves.easeInOutSine,
      'easeInQuad': Curves.easeInQuad,
      'easeOutQuad': Curves.easeOutQuad,
      'easeInOutQuad': Curves.easeInOutQuad,
      'easeInCubic': Curves.easeInCubic,
      'easeOutCubic': Curves.easeOutCubic,
      'easeInOutCubic': Curves.easeInOutCubic,
      'easeInExpo': Curves.easeInExpo,
      'easeOutExpo': Curves.easeOutExpo,
      'easeInOutExpo': Curves.easeInOutExpo,
      'easeInCirc': Curves.easeInCirc,
      'easeOutCirc': Curves.easeOutCirc,
      'easeInOutCirc': Curves.easeInOutCirc,
      'easeInBack': Curves.easeInBack,
      'easeOutBack': Curves.easeOutBack,
      'easeInOutBack': Curves.easeInOutBack,
      'elasticIn': Curves.elasticIn,
      'elasticOut': Curves.elasticOut,
      'elasticInOut': Curves.elasticInOut,
      'bounceIn': Curves.bounceIn,
      'bounceOut': Curves.bounceOut,
      'bounceInOut': Curves.bounceInOut,
      'decelerate': Curves.decelerate,
      'fastOutSlowIn': Curves.fastOutSlowIn,
    };

    for (final entry in curves.entries) {
      test('${entry.key} returns 0 at t=0', () {
        expect(entry.value.transform(0.0), closeTo(0.0, 0.01));
      });

      test('${entry.key} returns 1 at t=1', () {
        expect(entry.value.transform(1.0), closeTo(1.0, 0.01));
      });
    }
  });
}
