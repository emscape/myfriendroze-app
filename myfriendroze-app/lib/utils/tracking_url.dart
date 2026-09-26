/// Builds a carrier tracking URL so Roze doesn't have to paste one manually.
/// Returns null for an empty tracking number or a carrier not in this known
/// set (e.g. free-text entry) -- callers fall back to manual URL entry.
String? buildTrackingUrl(String carrier, String trackingNumber) {
  final trimmedNumber = trackingNumber.trim();
  if (trimmedNumber.isEmpty) return null;

  final encodedNumber = Uri.encodeComponent(trimmedNumber);

  switch (carrier.trim().toLowerCase()) {
    case 'usps':
      return 'https://tools.usps.com/go/TrackConfirmAction?tLabels=$encodedNumber';
    case 'ups':
      return 'https://www.ups.com/track?tracknum=$encodedNumber';
    case 'fedex':
      return 'https://www.fedex.com/fedextrack/?trknbr=$encodedNumber';
    case 'dhl':
      return 'https://www.dhl.com/us-en/home/tracking/tracking-express.html?submit=1&tracking-id=$encodedNumber';
    default:
      return null;
  }
}
