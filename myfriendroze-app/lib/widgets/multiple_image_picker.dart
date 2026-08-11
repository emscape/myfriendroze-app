import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum _ImageSourceChoice { camera, library }

class MultipleImagePicker extends StatefulWidget {
  final List<String> initialImageUrls;
  final Function(List<File>?, List<Uint8List>?) onImagesChanged;
  final int maxImages;
  final String labelText;

  const MultipleImagePicker({
    super.key,
    this.initialImageUrls = const [],
    required this.onImagesChanged,
    this.maxImages = 5,
    this.labelText = 'Product Images',
  });

  @override
  State<MultipleImagePicker> createState() => _MultipleImagePickerState();
}

class _MultipleImagePickerState extends State<MultipleImagePicker> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedFiles = [];
  final List<Uint8List> _selectedBytes = [];
  final List<String> _existingUrls = [];

  @override
  void initState() {
    super.initState();
    _existingUrls.addAll(widget.initialImageUrls);
  }

  Future<void> _pickImages() async {
    final source = await _chooseSource();
    if (source == null) return; // dismissed

    try {
      final List<XFile> images;
      if (source == _ImageSourceChoice.camera) {
        // Single shot only — a multi-select file input (the `multiple`
        // attribute pickMultiImage() sets on web) makes iOS Safari drop the
        // camera option entirely, since you can't take several photos in
        // one capture session. pickImage() avoids `multiple` altogether.
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        images = image == null ? [] : [image];
      } else {
        images = await _imagePicker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      }

      if (images.isNotEmpty) {
        final int remainingSlots = widget.maxImages - _getTotalImageCount();
        final List<XFile> imagesToAdd = images.take(remainingSlots).toList();

        if (kIsWeb) {
          final List<Uint8List> newBytes = [];
          for (final image in imagesToAdd) {
            final bytes = await image.readAsBytes();
            newBytes.add(bytes);
          }
          setState(() {
            _selectedBytes.addAll(newBytes);
          });
        } else {
          final List<File> newFiles = imagesToAdd
              .map((image) => File(image.path))
              .toList();
          setState(() {
            _selectedFiles.addAll(newFiles);
          });
        }

        _notifyChanges();
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Future<_ImageSourceChoice?> _chooseSource() {
    return showModalBottomSheet<_ImageSourceChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, _ImageSourceChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Library'),
              onTap: () => Navigator.pop(context, _ImageSourceChoice.library),
            ),
          ],
        ),
      ),
    );
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingUrls.removeAt(index);
    });
    _notifyChanges();
  }

  void _removeNewImage(int index) {
    setState(() {
      if (kIsWeb) {
        _selectedBytes.removeAt(index);
      } else {
        _selectedFiles.removeAt(index);
      }
    });
    _notifyChanges();
  }

  void _notifyChanges() {
    widget.onImagesChanged(
      _selectedFiles.isEmpty ? null : _selectedFiles,
      _selectedBytes.isEmpty ? null : _selectedBytes,
    );
  }

  int _getTotalImageCount() {
    return _existingUrls.length +
        (kIsWeb ? _selectedBytes.length : _selectedFiles.length);
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _getTotalImageCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.labelText} ($totalImages/${widget.maxImages})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Image grid
        if (totalImages > 0)
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing images
                ..._existingUrls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return _buildImageCard(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image),
                    ),
                    onRemove: () => _removeExistingImage(index),
                  );
                }),

                // New images
                if (kIsWeb)
                  ..._selectedBytes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final bytes = entry.value;
                    return _buildImageCard(
                      child: Image.memory(bytes, fit: BoxFit.cover),
                      onRemove: () => _removeNewImage(index),
                    );
                  })
                else
                  ..._selectedFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return _buildImageCard(
                      child: Image.file(file, fit: BoxFit.cover),
                      onRemove: () => _removeNewImage(index),
                    );
                  }),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Add images button
        if (totalImages < widget.maxImages)
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(totalImages == 0 ? 'Add Images' : 'Add More Images'),
          ),
      ],
    );
  }

  Widget _buildImageCard({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 100, height: 100, child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
