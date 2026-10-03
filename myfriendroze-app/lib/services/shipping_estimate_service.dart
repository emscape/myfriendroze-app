import 'package:cloud_functions/cloud_functions.dart';

/// One piece's shipping box, as the estimateShipping callable expects it.
class ParcelInput {
  final double weightGrams;
  final double lengthIn;
  final double widthIn;
  final double heightIn;

  const ParcelInput({
    required this.weightGrams,
    required this.lengthIn,
    required this.widthIn,
    required this.heightIn,
  });
}

class ShippingQuote {
  final String label;
  final String zip;
  final double amount;

  const ShippingQuote({required this.label, required this.zip, required this.amount});
}

/// USPS Ground Advantage quotes for one box, plus the amount the
/// callable suggests building into the price (the farthest lower-48 quote
/// plus packing, rounded up). testMode: the prices came from a Shippo test
/// key, not live rates.
class ShippingEstimate {
  final List<ShippingQuote> quotes;
  final int suggestedShipping;
  final bool testMode;

  const ShippingEstimate({
    required this.quotes,
    required this.suggestedShipping,
    required this.testMode,
  });

  factory ShippingEstimate.fromMap(Map<String, dynamic> map) {
    final quotes = (map['quotes'] as List)
        .map((q) => Map<String, dynamic>.from(q as Map))
        .map((q) => ShippingQuote(
              label: q['label'] as String,
              zip: q['zip'] as String,
              // Whole-dollar amounts arrive as ints over the callable's JSON.
              amount: (q['amount'] as num).toDouble(),
            ))
        .toList();
    return ShippingEstimate(
      quotes: quotes,
      suggestedShipping: (map['suggestedShipping'] as num).toInt(),
      testMode: map['testMode'] == true,
    );
  }
}

/// What the product form needs from the estimate, so widget tests can
/// pass a fake instead of calling Firebase.
abstract class ShippingEstimator {
  Future<ShippingEstimate> estimate(ParcelInput parcel);
}

/// Calls the estimateShipping callable in firebase/functions'
/// estimateShipping.js (Shippo quotes, admin-only). Thin platform-channel
/// wiring, like OrderShippingService -- verified by manual testing.
class ShippingEstimateService implements ShippingEstimator {
  // Must match the region estimateShipping.js is deployed to; the
  // cloud_functions package defaults to us-central1.
  static const _region = 'us-west1';

  @override
  Future<ShippingEstimate> estimate(ParcelInput parcel) async {
    final callable = FirebaseFunctions.instanceFor(region: _region)
        .httpsCallable('estimateShipping');
    final result = await callable.call({
      'weightGrams': parcel.weightGrams,
      'lengthIn': parcel.lengthIn,
      'widthIn': parcel.widthIn,
      'heightIn': parcel.heightIn,
    });
    return ShippingEstimate.fromMap(Map<String, dynamic>.from(result.data as Map));
  }
}
