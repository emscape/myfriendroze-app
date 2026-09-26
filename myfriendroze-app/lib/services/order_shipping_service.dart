import 'package:cloud_functions/cloud_functions.dart';

/// Calls the sendOrderShippedNotification callable in firebase/functions'
/// orderShipped.js. Thin platform-channel wiring, same "thin wiring"
/// tradeoff that callable's own onCall wrapper takes -- not usefully
/// unit-testable, verified by manual testing instead (see CLAUDE.md's
/// mandatory manual-test-before-merge rule for this app).
class OrderShippingService {
  // Must match the region orderShipped.js is actually deployed to
  // (onCall({region: "us-west1", ...})) -- the cloud_functions package
  // defaults to us-central1 and would silently fail to find the function
  // without this.
  static const _region = 'us-west1';

  Future<Map<String, dynamic>> markShipped({
    required String orderId,
    required Map<String, dynamic> shippingDetails,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: _region)
        .httpsCallable('sendOrderShippedNotification');
    final result = await callable.call({
      'orderId': orderId,
      'shippingDetails': shippingDetails,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
