import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/saved_location_provider.dart';

// Tappable chips for the venue addresses Roze has saved (see
// SavedLocationProvider) — lets a form fill its location field from a
// previously-entered address instead of retyping it. Renders nothing until
// at least one location has been saved.
class SavedLocationChips extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const SavedLocationChips({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedLocationProvider>(
      builder: (context, savedLocationProvider, _) {
        if (savedLocationProvider.locations.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: savedLocationProvider.locations.map((saved) {
              return ActionChip(
                label: Text(saved.name),
                onPressed: () => onSelected(saved.address),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
