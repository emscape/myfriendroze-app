import 'dart:io';
import 'package:flutter/material.dart';

// The bordered "tap to add a photo" box used by the add/edit event form
// (see add_event_screen.dart). Shows the picked image once one exists,
// otherwise the placeholder prompt.
class ImagePickerBox extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onTap;
  final String placeholderText;

  const ImagePickerBox({
    super.key,
    required this.selectedImage,
    required this.onTap,
    this.placeholderText = 'Tap to add a photo (optional)',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(selectedImage!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(placeholderText, style: const TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}
