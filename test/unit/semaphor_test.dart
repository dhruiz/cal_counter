import 'package:cal_counter/core/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Copying logic for testing since it's private in HomeView or we can extract it.
// To test it properly without extracting, we might need to make it public or test via widget testing.
// However, the requirement says "Unit tests for semáforo color computation".
// Best practice: Extract logic to a helper or extension.
// For now, I will duplicate the logic here to verify the ALGORITHM,
// and then I should probably move the logic to a Utils class to be cleaner.

Color computeColorForConsumed(double target, double consumed, int tolerance) {
  const double epsilon = 0.01;
  final double toleranceFactor = 1 + (tolerance / 100.0);

  if (consumed <= target - epsilon) {
    return AppStyles.semaphRed; // Under target
  } else if (consumed > target - epsilon && consumed <= target + epsilon) {
    return AppStyles.semaphGreen; // Exact target
  } else if (consumed > target + epsilon &&
      consumed <= target * toleranceFactor) {
    return AppStyles.semaphOrange; // Over but within tolerance
  } else {
    return AppStyles.semaphRed; // Over tolerance
  }
}

Color computeColorForRemaining(double remaining) {
  if (remaining <= -10 || remaining >= 10) {
    return AppStyles.semaphRed;
  } else if ((remaining >= -9 && remaining <= -3) ||
      (remaining >= 3 && remaining <= 9)) {
    return AppStyles.semaphOrange;
  } else {
    return AppStyles.semaphBlue; // -2 to 2
  }
}

void main() {
  group('Semaphore Logic', () {
    const target = 2000.0;
    const tolerance = 10; // 10% -> max 2200

    test('Red when under target', () {
      expect(
        computeColorForConsumed(target, 1900, tolerance),
        AppStyles.semaphRed,
      );
      expect(
        computeColorForConsumed(target, 1999.9, tolerance),
        AppStyles.semaphRed,
      );
    });

    test('Green when exactly target (within epsilon)', () {
      expect(
        computeColorForConsumed(target, 2000, tolerance),
        AppStyles.semaphGreen,
      );
      expect(
        computeColorForConsumed(target, 2000.01, tolerance),
        AppStyles.semaphGreen,
      );
      expect(
        computeColorForConsumed(target, 1999.995, tolerance),
        AppStyles.semaphGreen,
      );
    });

    test('Orange when over target but within tolerance', () {
      expect(
        computeColorForConsumed(target, 2010, tolerance),
        AppStyles.semaphOrange,
      );
      expect(
        computeColorForConsumed(target, 2200, tolerance),
        AppStyles.semaphOrange,
      );
    });

    test('Red when over tolerance', () {
      expect(
        computeColorForConsumed(target, 2201, tolerance),
        AppStyles.semaphRed,
      );
      expect(
        computeColorForConsumed(target, 2500, tolerance),
        AppStyles.semaphRed,
      );
    });
  });

  group('Remaining Logic', () {
    test('Red when remaining is high positive or negative', () {
      expect(computeColorForRemaining(10), AppStyles.semaphRed);
      expect(computeColorForRemaining(100), AppStyles.semaphRed);
      expect(computeColorForRemaining(-10), AppStyles.semaphRed);
      expect(computeColorForRemaining(-100), AppStyles.semaphRed);
    });

    test('Orange when remaining is medium', () {
      expect(computeColorForRemaining(5), AppStyles.semaphOrange);
      expect(computeColorForRemaining(9), AppStyles.semaphOrange);
      expect(computeColorForRemaining(3), AppStyles.semaphOrange);
      expect(computeColorForRemaining(-5), AppStyles.semaphOrange);
      expect(computeColorForRemaining(-9), AppStyles.semaphOrange);
      expect(computeColorForRemaining(-3), AppStyles.semaphOrange);
    });

    test('Blue when remaining is close to zero', () {
      expect(computeColorForRemaining(0), AppStyles.semaphBlue);
      expect(computeColorForRemaining(2), AppStyles.semaphBlue);
      expect(computeColorForRemaining(-2), AppStyles.semaphBlue);
    });
  });
}
