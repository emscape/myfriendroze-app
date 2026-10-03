import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../services/shipping_estimate_service.dart';

/// "Estimate shipping" on the product form: USPS quotes for the piece's
/// shipping box and a suggested amount to build into its price.
/// Information only -- it never changes the price field.
class ShippingEstimatePanel extends StatefulWidget {
  final ShippingEstimator estimator;

  /// The weight and box size currently in the form, or null if any is
  /// missing.
  final ParcelInput? Function() readParcel;

  const ShippingEstimatePanel({
    super.key,
    required this.estimator,
    required this.readParcel,
  });

  @override
  State<ShippingEstimatePanel> createState() => _ShippingEstimatePanelState();
}

class _ShippingEstimatePanelState extends State<ShippingEstimatePanel> {
  static const _generalError = "Couldn't get a shipping estimate. Try again in a moment.";

  /// Codes the estimateShipping function throws with a message written for
  /// the admin. Any other code (e.g. "internal" when the call never reaches
  /// the function) carries Firebase's own text, so it gets [_generalError].
  static const _readableCodes = {'invalid-argument', 'permission-denied', 'unavailable'};

  bool _loading = false;
  String? _message;
  ShippingEstimate? _estimate;

  Future<void> _estimateShipping() async {
    final parcel = widget.readParcel();
    if (parcel == null) {
      setState(() {
        _estimate = null;
        _message = 'Enter the weight and all three box sizes first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _estimate = null;
    });
    try {
      final estimate = await widget.estimator.estimate(parcel);
      if (!mounted) return;
      setState(() => _estimate = estimate);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _message = _readableCodes.contains(e.code) ? (e.message ?? _generalError) : _generalError);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = _generalError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _estimateShipping,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.local_shipping_outlined),
          label: const Text('Estimate shipping'),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (estimate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('USPS Ground Advantage from 90065:'),
                for (final quote in estimate.quotes)
                  Text('${quote.label}: \$${quote.amount.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text(
                  'Suggested shipping to build into the price: \$${estimate.suggestedShipping}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (estimate.testMode)
                  const Text(
                    'These are Shippo test prices until the live key is set.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
