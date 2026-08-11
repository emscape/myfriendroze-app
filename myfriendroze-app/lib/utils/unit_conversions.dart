/// Conversions between the imperial units Roze enters in the product form
/// (pounds/ounces) and the metric grams Firestore's `weight` field stores.
///
/// Firestore keeps `weight` in grams because that's what the Astro site's
/// shipping calculator (astro/src/components/ShippingCalculator.astro) and
/// the product-sync API (astro/src/pages/api/products/*.js) already expect
/// — this file exists so the app's UI boundary is the only place that ever
/// has to think about pounds and ounces.
library;

const double gramsPerOunce = 28.349523125;
const double ouncesPerPound = 16;

/// Converts pounds + ounces to grams for storage in [Product.weight].
double lbsOzToGrams(double lbs, double oz) {
  final totalOunces = (lbs * ouncesPerPound) + oz;
  return totalOunces * gramsPerOunce;
}

/// A weight expressed as whole pounds plus remaining ounces, for
/// prefilling the two-field form when editing an existing product.
class LbsOz {
  final double lbs;
  final double oz;

  const LbsOz({required this.lbs, required this.oz});
}

/// Converts grams to pounds + ounces. Ounces are always normalized to the
/// range [0, 16) — a value that rounds up to 16 oz carries into the next
/// pound instead. Negative input (which should never occur, but a stored
/// value predating validation could be malformed) is treated as zero.
LbsOz gramsToLbsOz(double grams) {
  if (grams <= 0) return const LbsOz(lbs: 0, oz: 0);

  final totalOunces = grams / gramsPerOunce;
  final wholeLbs = (totalOunces / ouncesPerPound).floorToDouble();
  final remainingOz = totalOunces - (wholeLbs * ouncesPerPound);

  // Round to 1 decimal place to avoid floating point noise (e.g. 7.9999999).
  final roundedOz = (remainingOz * 10).round() / 10;

  if (roundedOz >= ouncesPerPound) {
    return LbsOz(lbs: wholeLbs + 1, oz: 0);
  }
  return LbsOz(lbs: wholeLbs, oz: roundedOz);
}
