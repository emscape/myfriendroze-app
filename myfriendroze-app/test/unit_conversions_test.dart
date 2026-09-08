import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/utils/unit_conversions.dart';

void main() {
  group('lbsOzToGrams', () {
    test('converts whole pounds with zero ounces', () {
      // 3 lb == 1360.77711 g, matching values already stored in
      // astro/src/data/products.js ("grams from CSV").
      expect(lbsOzToGrams(3, 0), closeTo(1360.77711, 0.001));
    });

    test('converts pounds and ounces combined', () {
      // 1 lb 8 oz == 24 oz
      expect(lbsOzToGrams(1, 8), closeTo(680.388555, 0.001));
    });

    test('converts ounces only', () {
      expect(lbsOzToGrams(0, 4), closeTo(113.398092, 0.001));
    });

    test('zero lbs and zero oz is zero grams', () {
      expect(lbsOzToGrams(0, 0), 0);
    });
  });

  group('gramsToLbsOz', () {
    test('round-trips a known whole-pound value', () {
      final result = gramsToLbsOz(1360.77711);
      expect(result.lbs, 3);
      expect(result.oz, closeTo(0, 0.05));
    });

    test('splits into pounds and remaining ounces', () {
      final result = gramsToLbsOz(680.388555); // 1 lb 8 oz
      expect(result.lbs, 1);
      expect(result.oz, closeTo(8, 0.05));
    });

    test('zero grams yields zero lbs and zero oz', () {
      final result = gramsToLbsOz(0);
      expect(result.lbs, 0);
      expect(result.oz, 0);
    });

    test('negative grams is treated as zero rather than throwing', () {
      final result = gramsToLbsOz(-5);
      expect(result.lbs, 0);
      expect(result.oz, 0);
    });

    test('rounds up into the next pound instead of displaying 16 oz', () {
      final almostThreeLb = (2 * 16 + 15.96) * 28.349523125;
      final result = gramsToLbsOz(almostThreeLb);
      expect(result.lbs, 3);
      expect(result.oz, 0);
    });
  });

  group('formatWeightGrams', () {
    test('rounds away floating-point noise from lbsOzToGrams', () {
      // Reported bug: the products list showed raw values like
      // "1530.87424875g" and "2.8349523125000005g" — lbsOzToGrams's exact
      // math is correct (see the group above), the noise is only a
      // problem once it hits an unformatted display.
      expect(formatWeightGrams(1530.87424875), '1531g');
      expect(formatWeightGrams(2.8349523125000005), '3g');
    });

    test('rounds to the nearest whole gram, not truncates', () {
      expect(formatWeightGrams(680.388555), '680g');
      expect(formatWeightGrams(113.398092), '113g');
    });

    test('zero grams formats as 0g', () {
      expect(formatWeightGrams(0), '0g');
    });
  });
}
