import 'package:flutter/material.dart';

// A bordered, tappable label/value box — used for the date/time/end-date
// pickers on the event form (see add_event_screen.dart), and reusable
// anywhere else a similar "tap to pick a value" field is needed.
class SelectorBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool fillWidth;

  const SelectorBox({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.fillWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fillWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
