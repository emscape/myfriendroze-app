import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/multiple_image_picker.dart';
import '../../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();

  List<File>? _selectedImages;
  List<Uint8List>? _selectedImageBytes;

  // Speech to text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // If editing, prefill fields
    final product = widget.productToEdit;
    if (product != null) {
      _titleController.text = product.title;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _weightController.text = product.weight.toString();
      // Note: image is not preloaded into _selectedImage; keep using existing URL unless replaced
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    }
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _descriptionController.text = result.recognizedWords;
          });
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      // If editing and no new images selected, we allow keeping existing imageUrls
      final isEditing = widget.productToEdit != null;

      // Allow products without images for testing
      // if (!isEditing &&
      //     _selectedImages == null &&
      //     _selectedImageBytes == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //         content: Text('Please select at least one product image')),
      //   );
      //   return;
      // }

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text);
      final weight = double.parse(_weightController.text);

      bool success = false;

      if (isEditing) {
        final existing = widget.productToEdit!;
        final updatedProduct = existing.copyWith(
          title: title,
          description: description,
          price: price,
          weight: weight,
          updatedAt: DateTime.now(),
        );

        success = await productProvider.updateProduct(
          updatedProduct,
          newImageFiles: _selectedImages,
          newImageBytesList: _selectedImageBytes,
        );
      } else {
        success = await productProvider.addProduct(
          title: title,
          description: description,
          price: price,
          weight: weight,
          imageFiles: _selectedImages,
          imageBytesList: _selectedImageBytes,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEditing
                  ? 'Product updated successfully!'
                  : 'Product added successfully!')),
        );
        context.go('/products');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Multiple Image picker
              MultipleImagePicker(
                initialImageUrls: widget.productToEdit?.imageUrls ?? [],
                maxImages: 5,
                onImagesChanged: (files, bytes) {
                  setState(() {
                    _selectedImages = files;
                    _selectedImageBytes = bytes;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Title field
              CustomTextField(
                controller: _titleController,
                labelText: 'Product Title',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field with speech-to-text
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                maxLines: 4,
                suffixIcon: _speechEnabled
                    ? IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : null,
                        ),
                        onPressed:
                            _isListening ? _stopListening : _startListening,
                      )
                    : null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              if (_isListening)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Listening... Tap the mic to stop',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Price and weight row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      labelText: 'Price (\$)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid price';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Price must be positive';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      labelText: 'Weight (g)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter weight';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid weight';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Weight must be positive';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Error message
              Consumer<ProductProvider>(
                builder: (context, productProvider, _) {
                  if (productProvider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        productProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Submit button
              Consumer<ProductProvider>(
                builder: (context, productProvider, _) {
                  final isEditing = widget.productToEdit != null;
                  return ElevatedButton(
                    onPressed: productProvider.isLoading ? null : _handleSubmit,
                    child: productProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Update Product' : 'Add Product'),
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
