import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/saved_location_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_box.dart';
import '../../widgets/saved_location_chips.dart';
import '../../widgets/selector_box.dart';

class AddEventScreen extends StatefulWidget {
  final Event? eventToEdit;

  const AddEventScreen({super.key, this.eventToEdit});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _saveLocationNameController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  // Defaults to the start time — a zero-length range is a safer default
  // than an inverted one, and it's immediately obvious on screen so it's
  // easy to notice and correct.
  TimeOfDay _selectedEndTime = TimeOfDay.now();
  bool _isMultiDay = false;
  DateTime? _selectedEndDate;
  bool _saveLocationForLater = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavedLocationProvider>(context, listen: false).loadLocations();
    });
    // Defaults to the start time for a brand-new event — overwritten below
    // when editing an existing one.
    _selectedEndTime = _selectedTime;

    // If editing, prefill fields
    final event = widget.eventToEdit;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _selectedDate = event.eventDate;
      _selectedTime = TimeOfDay.fromDateTime(event.eventDate);
      if (event.endDate != null) {
        _selectedEndTime = TimeOfDay.fromDateTime(event.endDate!);
        if (!_isSameDay(event.endDate!, event.eventDate)) {
          _isMultiDay = true;
          _selectedEndDate = event.endDate;
        }
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _saveLocationNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    // firstDate must be on or before initialDate or showDatePicker asserts
    // — reopening a past event to edit it (see events_screen.dart's edit
    // action) means _selectedDate can already be before DateTime.now().
    final firstDate = _selectedDate.isBefore(DateTime.now()) ? _selectedDate : DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // An end date earlier than the (now-moved) start date makes no
        // sense — clear it rather than silently submitting an inverted
        // range.
        if (_selectedEndDate != null && _selectedEndDate!.isBefore(_selectedDate)) {
          _selectedEndDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final initialEndDate = _selectedEndDate ?? _selectedDate;
    final firstDate = _selectedDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialEndDate.isBefore(firstDate) ? firstDate : initialEndDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
    );

    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  DateTime get _eventDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  bool get _isEditing => widget.eventToEdit != null;

  // Always returns a value now (start+end time are both always captured) —
  // the end DATE only differs from the start date when _isMultiDay is on.
  DateTime get _endDateTime {
    final endDatePart = _isMultiDay && _selectedEndDate != null ? _selectedEndDate! : _selectedDate;
    return DateTime(
      endDatePart.year,
      endDatePart.month,
      endDatePart.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final location = _locationController.text.trim();

      bool success;
      if (_isEditing) {
        final updatedEvent = widget.eventToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          eventDate: _eventDateTime,
          endDate: _endDateTime,
          location: location,
        );
        success = await eventProvider.updateEvent(updatedEvent, newImageFile: _selectedImage);
      } else {
        success = await eventProvider.addEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          eventDate: _eventDateTime,
          endDate: _endDateTime,
          location: location,
          imageFile: _selectedImage,
        );
      }

      // Saving the location is best-effort and shouldn't block navigating
      // away on a successful event save — a failure here just means Roze
      // has to type the address again next time.
      if (success && _saveLocationForLater && location.isNotEmpty && mounted) {
        final name = _saveLocationNameController.text.trim();
        await Provider.of<SavedLocationProvider>(context, listen: false).addLocation(
          name: name.isNotEmpty ? name : location,
          address: location,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Event updated successfully!' : 'Event added successfully!')),
        );
        context.go('/events');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Add Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/events'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Optional image picker
              ImagePickerBox(selectedImage: _selectedImage, onTap: _showImageSourceDialog),
              const SizedBox(height: 24),

              // Title field
              CustomTextField(
                controller: _titleController,
                labelText: 'Event Title',
                enableVoice: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                maxLines: 4,
                enableVoice: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Saved locations — pick a frequent venue instead of retyping
              // its address (Roze enters these herself; see
              // SavedLocationProvider).
              SavedLocationChips(
                onSelected: (address) => setState(() => _locationController.text = address),
              ),

              // Location field
              CustomTextField(
                controller: _locationController,
                labelText: 'Location',
                enableVoice: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _saveLocationForLater,
                title: const Text('Save this location for reuse'),
                onChanged: (checked) {
                  setState(() {
                    _saveLocationForLater = checked ?? false;
                  });
                },
              ),
              if (_saveLocationForLater)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CustomTextField(
                    controller: _saveLocationNameController,
                    labelText: "Save as (e.g. 'Jackalope Pasadena')",
                  ),
                ),
              const SizedBox(height: 16),

              // Start date/time
              Row(
                children: [
                  Expanded(
                    child: SelectorBox(
                      label: 'Start Date',
                      value: dateFormat.format(_selectedDate),
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SelectorBox(
                      label: 'Start Time',
                      value: timeFormat.format(_eventDateTime),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _isMultiDay,
                title: const Text('Multi-day event'),
                onChanged: (checked) {
                  setState(() {
                    _isMultiDay = checked ?? false;
                    if (!_isMultiDay) {
                      _selectedEndDate = null;
                    }
                  });
                },
              ),
              // End date/time — an end time is always captured (e.g. "11a -
              // 6p"), but the end DATE only shows up once Multi-day event
              // is checked; otherwise it's implicitly the same day.
              Row(
                children: [
                  if (_isMultiDay) ...[
                    Expanded(
                      child: SelectorBox(
                        label: 'End Date',
                        value: _selectedEndDate != null
                            ? dateFormat.format(_selectedEndDate!)
                            : 'Tap to select the last day',
                        onTap: _selectEndDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: SelectorBox(
                      label: 'End Time',
                      value: timeFormat.format(_endDateTime),
                      onTap: _selectEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Error message
              Consumer<EventProvider>(
                builder: (context, eventProvider, _) {
                  if (eventProvider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        eventProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Submit button
              Consumer<EventProvider>(
                builder: (context, eventProvider, _) {
                  return ElevatedButton(
                    onPressed: eventProvider.isLoading ? null : _handleSubmit,
                    child: eventProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Update Event' : 'Add Event'),
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
