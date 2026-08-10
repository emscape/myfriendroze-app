import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/gallery_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/multiple_image_picker.dart';
import '../../models/gallery_photo.dart';

class AddGalleryPhotoScreen extends StatefulWidget {
  final GalleryPhoto? photoToEdit;

  const AddGalleryPhotoScreen({super.key, this.photoToEdit});

  @override
  State<AddGalleryPhotoScreen> createState() => _AddGalleryPhotoScreenState();
}

class _AddGalleryPhotoScreenState extends State<AddGalleryPhotoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _altTextController = TextEditingController();
  final _captionController = TextEditingController();
  final _linkController = TextEditingController();

  List<File>? _selectedImages;
  List<Uint8List>? _selectedImageBytes;

  @override
  void initState() {
    super.initState();

    final photo = widget.photoToEdit;
    if (photo != null) {
      _altTextController.text = photo.altText;
      _captionController.text = photo.caption ?? '';
      _linkController.text = photo.link ?? '';
      // Note: image is not preloaded into _selectedImages; keep using the
      // existing URL unless a replacement is picked.
    }
  }

  @override
  void dispose() {
    _altTextController.dispose();
    _captionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.photoToEdit != null;

    if (!isEditing && _selectedImages == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo')),
      );
      return;
    }

    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    final altText = _altTextController.text.trim();
    final caption = _captionController.text.trim();
    final link = _linkController.text.trim();

    bool success;
    if (isEditing) {
      success = await galleryProvider.updateGalleryPhoto(
        widget.photoToEdit!,
        altText: altText,
        caption: caption.isEmpty ? null : caption,
        link: link.isEmpty ? null : link,
        newImageFiles: _selectedImages,
        newImageBytesList: _selectedImageBytes,
      );
    } else {
      success = await galleryProvider.addGalleryPhoto(
        altText: altText,
        caption: caption.isEmpty ? null : caption,
        link: link.isEmpty ? null : link,
        imageFiles: _selectedImages,
        imageBytesList: _selectedImageBytes,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing
                ? 'Gallery photo updated successfully!'
                : 'Gallery photo added successfully!')),
      );
      context.go('/gallery');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.photoToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Gallery Photo' : 'Add Gallery Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/gallery'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MultipleImagePicker(
                initialImageUrls:
                    widget.photoToEdit != null ? [widget.photoToEdit!.imageUrl] : [],
                maxImages: 1,
                labelText: 'Gallery Photo',
                onImagesChanged: (files, bytes) {
                  setState(() {
                    _selectedImages = files;
                    _selectedImageBytes = bytes;
                  });
                },
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _altTextController,
                labelText: 'Alt Text',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the photo for accessibility';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _captionController,
                labelText: 'Caption (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _linkController,
                labelText: 'Link (optional)',
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.hasScheme) {
                    return 'Enter a full URL, e.g. https://instagram.com/p/...';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Consumer<GalleryProvider>(
                builder: (context, galleryProvider, _) {
                  if (galleryProvider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        galleryProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              Consumer<GalleryProvider>(
                builder: (context, galleryProvider, _) {
                  return ElevatedButton(
                    onPressed:
                        galleryProvider.isLoading ? null : _handleSubmit,
                    child: galleryProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Update Photo' : 'Add Photo'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
