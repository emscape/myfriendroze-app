import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// The bordered "tap to add a photo" box used by the add/edit event form
// (see add_event_screen.dart). Shows the picked image once one exists,
// otherwise the placeholder prompt.
//
// Accepts either selectedImage (a dart:io File, native platforms) or
// selectedImageBytes (web — dart:io isn't implemented there, so
// Image.file would fail the same way Storage's putFile() does). The
// caller is expected to only ever populate one of the two, matching how
// the picking side already branches on kIsWeb.
class ImagePickerBox extends StatelessWidget {
  final File? selectedImage;
  final Uint8List? selectedImageBytes;
  final VoidCallback onTap;
  final String placeholderText;

  const ImagePickerBox({
    super.key,
    required this.selectedImage,
    this.selectedImageBytes,
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
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
      );
    }
    if (selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(selectedImage!, fit: BoxFit.cover),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        Text(placeholderText, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
