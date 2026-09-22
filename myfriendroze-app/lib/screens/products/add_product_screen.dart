import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/multiple_image_picker.dart';
import '../../widgets/selector_box.dart';
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
  final _shippingBoxHeightController = TextEditingController();
  final _shippingBoxWidthController = TextEditingController();
  final _shippingBoxDepthController = TextEditingController();

  List<File>? _selectedImages;
  List<Uint8List>? _selectedImageBytes;

  // Delayed/scheduled publish. Defaults mirror add_event_screen.dart's
  // date/time picker defaults (tomorrow, current time-of-day).
  bool _delayPosting = false;
  DateTime _publishDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _publishTime = TimeOfDay.now();

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
      if (product.shippingBoxHeightIn > 0) {
        _shippingBoxHeightController.text =
            product.shippingBoxHeightIn.toString();
      }
      if (product.shippingBoxWidthIn > 0) {
        _shippingBoxWidthController.text =
            product.shippingBoxWidthIn.toString();
      }
      if (product.shippingBoxDepthIn > 0) {
        _shippingBoxDepthController.text =
            product.shippingBoxDepthIn.toString();
      }
      // Only prefill the delay toggle for a schedule that hasn't happened
      // yet — a publishAt already in the past means the product is already
      // live, and re-showing it as "delayed" would block an unrelated edit
      // (e.g. a price change) behind the future-only validation below.
      if (product.publishAt != null &&
          product.publishAt!.isAfter(DateTime.now())) {
        _delayPosting = true;
        _publishDate = product.publishAt!;
        _publishTime = TimeOfDay.fromDateTime(product.publishAt!);
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
    _shippingBoxHeightController.dispose();
    _shippingBoxWidthController.dispose();
    _shippingBoxDepthController.dispose();
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

  Future<void> _selectPublishDate() async {
    final now = DateTime.now();
    // initialDate must be on or after firstDate (now) or showDatePicker
    // asserts — _publishDate could already be in the past from the
    // already-live-schedule case initState skips prefilling for, but stay
    // defensive here too.
    final initialDate = _publishDate.isBefore(now) ? now : _publishDate;
    // Same constraint applies to lastDate: a product already scheduled
    // more than 365 days out (reachable by editing) would put initialDate
    // after this fixed cap and crash showDatePicker's assertion — same fix
    // as add_event_screen.dart's _selectDate/_selectEndDate.
    final defaultLastDate = now.add(const Duration(days: 365));
    final lastDate = _publishDate.isAfter(defaultLastDate) ? _publishDate : defaultLastDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() => _publishDate = picked);
    }
  }

  Future<void> _selectPublishTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _publishTime,
    );

    if (picked != null) {
      setState(() => _publishTime = picked);
    }
  }

  DateTime get _publishDateTime {
    return DateTime(
      _publishDate.year,
      _publishDate.month,
      _publishDate.day,
      _publishTime.hour,
      _publishTime.minute,
    );
  }

  // Date pickers alone can't stop a past moment: firstDate keeps the DATE
  // from going before today, but a today's-date + earlier-time combination
  // still slips through, e.g. picking today then a time already passed.
  String? get _publishAtError {
    if (!_delayPosting) return null;
    if (!_publishDateTime.isAfter(DateTime.now())) {
      return 'Delayed publish date/time must be in the future.';
    }
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
      final shippingBoxHeightIn =
          _parseOptionalDouble(_shippingBoxHeightController.text);
      final shippingBoxWidthIn =
          _parseOptionalDouble(_shippingBoxWidthController.text);
      final shippingBoxDepthIn =
          _parseOptionalDouble(_shippingBoxDepthController.text);

      final publishAtError = _publishAtError;
      if (publishAtError != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(publishAtError)));
        return;
      }

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
          shippingBoxHeightIn: shippingBoxHeightIn,
          shippingBoxWidthIn: shippingBoxWidthIn,
          shippingBoxDepthIn: shippingBoxDepthIn,
          updatedAt: DateTime.now(),
          publishAt: _delayPosting ? _publishDateTime : null,
          clearPublishAt: !_delayPosting,
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
          shippingBoxHeightIn: shippingBoxHeightIn,
          shippingBoxWidthIn: shippingBoxWidthIn,
          shippingBoxDepthIn: shippingBoxDepthIn,
          publishAt: _delayPosting ? _publishDateTime : null,
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
              const SizedBox(height: 16),

              // Shipping box dimensions row (height/width/depth, inches —
              // optional). Independent of the item's own dimensions above:
              // fragile ceramics typically ship in a larger, padded box.
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Shipping box dimensions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _shippingBoxHeightController,
                      labelText: 'Box height (in)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateOptionalPositive,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _shippingBoxWidthController,
                      labelText: 'Box width (in)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateOptionalPositive,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _shippingBoxDepthController,
                      labelText: 'Box depth (in)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateOptionalPositive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Delayed/scheduled publish -- product stays hidden on the
              // public site until this date/time (see products-live.js and
              // firestore.rules in the site repo).
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _delayPosting,
                title: const Text('Delay posting'),
                subtitle: const Text('Hide this product until a chosen date/time'),
                onChanged: (checked) {
                  setState(() {
                    _delayPosting = checked ?? false;
                  });
                },
              ),
              if (_delayPosting) ...[
                Row(
                  children: [
                    Expanded(
                      child: SelectorBox(
                        label: 'Publish Date',
                        value: DateFormat('MMM dd, yyyy').format(_publishDateTime),
                        onTap: _selectPublishDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SelectorBox(
                        label: 'Publish Time',
                        value: DateFormat('h:mm a').format(_publishDateTime),
                        onTap: _selectPublishTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),

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
