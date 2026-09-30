import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_location.dart';
import '../providers/saved_location_provider.dart';
import 'custom_text_field.dart';

// Dropdown for Roze's saved venue addresses (see SavedLocationProvider),
// attached directly to the location field (Trello S9sAvkbW) -- replaces
// the earlier tap-a-chip pattern with a real Autocomplete-backed dropdown.
// Typing a brand-new one-off address (no saved match) still works freely;
// this only ever offers suggestions, never restricts input.
//
// Uses RawAutocomplete directly rather than the higher-level Autocomplete
// widget -- Autocomplete has no way to accept an externally-owned
// TextEditingController, which this needs so the parent form's
// _locationController stays the single source of truth (read on submit,
// pre-filled when editing an existing event).
class SavedLocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  const SavedLocationAutocomplete({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
  });

  @override
  State<SavedLocationAutocomplete> createState() => _SavedLocationAutocompleteState();
}

class _SavedLocationAutocompleteState extends State<SavedLocationAutocomplete> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<SavedLocationProvider>().locations;

    return RawAutocomplete<SavedLocation>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (location) => location.address,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return locations;
        final query = textEditingValue.text.toLowerCase();
        return locations.where(
          (location) =>
              location.name.toLowerCase().contains(query) ||
              location.address.toLowerCase().contains(query),
        );
      },
      onSelected: (_) => FocusScope.of(context).unfocus(),
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        return CustomTextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          labelText: widget.labelText,
          enableVoice: true,
          validator: widget.validator,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionsList = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, minWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionsList.length,
                itemBuilder: (context, index) {
                  final location = optionsList[index];
                  return ListTile(
                    title: Text(location.name),
                    subtitle: Text(
                      location.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelected(location),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
