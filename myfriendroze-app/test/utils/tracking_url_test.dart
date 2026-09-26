import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/utils/tracking_url.dart';

void main() {
  group('buildTrackingUrl', () {
    test('builds a USPS tracking URL', () {
      final url = buildTrackingUrl('USPS', '9400111899223197428490');

      expect(url, 'https://tools.usps.com/go/TrackConfirmAction?tLabels=9400111899223197428490');
    });

    test('builds a UPS tracking URL', () {
      final url = buildTrackingUrl('UPS', '1Z999AA10123456784');

      expect(url, 'https://www.ups.com/track?tracknum=1Z999AA10123456784');
    });

    test('builds a FedEx tracking URL', () {
      final url = buildTrackingUrl('FedEx', '999999999999');

      expect(url, 'https://www.fedex.com/fedextrack/?trknbr=999999999999');
    });

    test('builds a DHL tracking URL', () {
      final url = buildTrackingUrl('DHL', '1234567890');

      expect(url, 'https://www.dhl.com/us-en/home/tracking/tracking-express.html?submit=1&tracking-id=1234567890');
    });

    test('matches carrier names case-insensitively and trims whitespace', () {
      final url = buildTrackingUrl(' usps ', '9400111899223197428490');

      expect(url, 'https://tools.usps.com/go/TrackConfirmAction?tLabels=9400111899223197428490');
    });

    test('returns null for an unrecognized/free-text carrier', () {
      final url = buildTrackingUrl('Local Courier', '12345');

      expect(url, isNull);
    });

    test('returns null when the tracking number is empty', () {
      final url = buildTrackingUrl('USPS', '');

      expect(url, isNull);
    });

    test('URL-encodes a tracking number containing special characters', () {
      final url = buildTrackingUrl('USPS', 'ABC 123/456');

      expect(url, 'https://tools.usps.com/go/TrackConfirmAction?tLabels=ABC%20123%2F456');
    });
  });
}
