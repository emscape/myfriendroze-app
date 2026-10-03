import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/services/shipping_estimate_service.dart';

void main() {
  group('ShippingEstimate.fromMap', () {
    test('reads the quotes, suggestion and test-mode flag the callable returns', () {
      final estimate = ShippingEstimate.fromMap({
        'quotes': [
          {'label': 'Los Angeles', 'zip': '90012', 'amount': 5.98},
          {'label': 'New York', 'zip': '10001', 'amount': 11.3},
          // Whole-dollar amounts arrive as ints over the callable's JSON.
          {'label': 'Alaska / Hawaii', 'zip': '96813', 'amount': 16},
        ],
        'suggestedShipping': 14,
        'testMode': true,
      });

      expect(estimate.quotes.map((q) => q.label).toList(),
          ['Los Angeles', 'New York', 'Alaska / Hawaii']);
      expect(estimate.quotes.map((q) => q.amount).toList(), [5.98, 11.3, 16.0]);
      expect(estimate.suggestedShipping, 14);
      expect(estimate.testMode, isTrue);
    });

    test('treats a missing testMode as live prices', () {
      final estimate = ShippingEstimate.fromMap({
        'quotes': <Map<String, dynamic>>[],
        'suggestedShipping': 12,
      });

      expect(estimate.testMode, isFalse);
    });
  });
}
