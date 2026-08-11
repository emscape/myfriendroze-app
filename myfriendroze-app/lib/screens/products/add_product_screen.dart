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
import '../../utils/unit_conversions.dart';

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
  final _weightLbsController = TextEditingController();
  final _weightOzController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();

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
      final weightLbsOz = gramsToLbsOz(product.weight);
      _weightLbsController.text = weightLbsOz.lbs.toString();
      _weightOzController.text = weightLbsOz.oz.toString();
      if (product.heightIn > 0) {
        _heightController.text = product.heightIn.toString();
      }
      if (product.widthIn > 0) {
        _widthController.text = product.widthIn.toString();
      }
      if (product.depthIn > 0) {
        _depthController.text = product.depthIn.toString();
      }
      // Note: image is not preloaded into _selectedImage; keep using existing URL unless replaced
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _weightLbsController.dispose();
    _weightOzController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _depthController.dispose();
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

  /// Dimension fields are optional (existing products predate them), so a
  /// blank entry is treated as "not measured" rather than a validation error.
  double _parseOptionalDouble(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0.0;
    return double.tryParse(trimmed) ?? 0.0;
  }

  String? _validateOptionalPositive(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Invalid number';
    if (parsed <= 0) return 'Must be positive';
    return null;
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

      final lbsText = _weightLbsController.text.trim();
      final ozText = _weightOzController.text.trim();
      final lbs = lbsText.isEmpty ? 0.0 : double.parse(lbsText);
      final oz = ozText.isEmpty ? 0.0 : double.parse(ozText);
      final weight = lbsOzToGrams(lbs, oz);

      final heightIn = _parseOptionalDouble(_heightController.text);
      final widthIn = _parseOptionalDouble(_widthController.text);
      final depthIn = _parseOptionalDouble(_depthController.text);

      bool success = false;

      if (isEditing) {
        final existing = widget.productToEdit!;
        final updatedProduct = existing.copyWith(
          title: title,
          description: description,
          price: price,
          weight: weight,
          heightIn: heightIn,
          widthIn: widthIn,
          depthIn: depthIn,
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
          heightIn: heightIn,
          widthIn: widthIn,
          depthIn: depthIn,
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

              // Price
              CustomTextField(
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
              const SizedBox(height: 16),

              // Weight row (lbs + oz)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _weightLbsController,
                      labelText: 'Weight (lbs)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final lbsText = value?.trim() ?? '';
                        final ozText = _weightOzController.text.trim();
                        final lbs =
                            lbsText.isEmpty ? 0.0 : double.tryParse(lbsText);
                        if (lbs == null) {
                          return 'Invalid';
                        }
                        if (lbs < 0) {
                          return 'Must be 0 or more';
                        }
                        final oz =
                            ozText.isEmpty ? 0.0 : double.tryParse(ozText);
                        if (oz != null && lbs <= 0 && oz <= 0) {
                          return 'Enter a weight';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _weightOzController,
                      labelText: 'Weight (oz)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final ozText = value?.trim() ?? '';
                        final lbsText = _weightLbsController.text.trim();
                        final oz =
                            ozText.isEmpty ? 0.0 : double.tryParse(ozText);
                        if (oz == null) {
                          return 'Invalid';
                        }
                        if (oz < 0 || oz >= 16) {
                          return '0-15 (use lbs for 16+)';
                        }
                        final lbs =
                            lbsText.isEmpty ? 0.0 : double.tryParse(lbsText);
                        if (lbs != null && lbs <= 0 && oz <= 0) {
                          return 'Enter a weight';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dimensions row (height/width/depth, inches — optional)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      labelText: 'Height (in)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateOptionalPositive,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _widthController,
                      labelText: 'Width (in)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateOptionalPositive,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _depthController,
                      labelText: 'Depth (in)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateOptionalPositive,
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
