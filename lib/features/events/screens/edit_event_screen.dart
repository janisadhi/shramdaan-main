import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/event_location_picker.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _carryController;
  late TextEditingController _providedController;

  DateTime? _selectedDate;
  String? _selectedCategory;
  Uint8List? _imageBytes;
  String? _imageName;
  EventLocationData? _selectedLocation;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _categories = [
    'Clean Up',
    'Plantation',
    'Donation',
    'Construction',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _carryController = TextEditingController(
      text: widget.event.thingsToCarry.join(', '),
    );
    _providedController = TextEditingController(
      text: widget.event.thingsProvided.join(', '),
    );
    _selectedDate = widget.event.eventDate;
    _selectedCategory = widget.event.category;
    if (widget.event.hasCoordinates) {
      _selectedLocation = EventLocationData(
        latitude: widget.event.latitude!,
        longitude: widget.event.longitude!,
        formattedAddress: widget.event.formattedAddress,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _carryController.dispose();
    _providedController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        _imageName = pickedFile.name;
        _imageBytes = await pickedFile.readAsBytes();
        setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open your gallery. Please allow photo access and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _updateForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedCategory == null ||
        _selectedLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the form and confirm the event location.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String finalImageUrl;
    if (_imageBytes != null && _imageName != null) {
      final newImageUrl = await _firestoreService.uploadImage(
        imageBytes: _imageBytes!,
        fileName: _imageName!,
      );
      if (newImageUrl == null || newImageUrl.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image upload failed. Please try another photo or check Firebase Storage setup.',
            ),
          ),
        );
        return;
      }
      finalImageUrl = newImageUrl ?? widget.event.imageUrl;
    } else {
      finalImageUrl = widget.event.imageUrl;
    }

    final updatedData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _selectedLocation!.formattedAddress,
      'formattedAddress': _selectedLocation!.formattedAddress,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'eventDate': _selectedDate,
      'category': _selectedCategory,
      'imageUrl': finalImageUrl,
      'thingsToCarry': _carryController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'thingsProvided': _providedController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };

    if (widget.event.status == 'rejected') {
      updatedData['status'] = 'pending';
      updatedData['rejectionReason'] = null;
      updatedData['isFeatured'] = false;
    }

    await _firestoreService.updateEvent(widget.event.id, updatedData);

    if (mounted) {
      final message = widget.event.status == 'rejected'
          ? 'Event updated and resubmitted for review.'
          : 'Event updated successfully.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isResubmission = widget.event.status == 'rejected';

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(isResubmission ? 'Edit & Resubmit' : 'Edit Event'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _updateForm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isResubmission
                    ? Icons.refresh_rounded
                    : Icons.check_circle_outline),
            label: Text(
              _isLoading
                  ? 'Saving...'
                  : (isResubmission ? 'Update & Resubmit' : 'Save Changes'),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isResubmission ? 'Refine and resubmit' : 'Update your event',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isResubmission
                        ? 'Make the requested changes and send the event back into review.'
                        : 'Refresh the details, timing, image, or location for this Shramdaan.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (isResubmission &&
                      widget.event.rejectionReason != null &&
                      widget.event.rejectionReason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Admin feedback: ${widget.event.rejectionReason!}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            _EditFormSection(
              title: 'Cover image',
              subtitle: 'Replace the event image from your device.',
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : widget.event.imageUrl.isNotEmpty
                                ? Image.network(
                                    widget.event.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _ImagePlaceholder(
                                      theme: theme,
                                      text: 'Could not load image',
                                    ),
                                  )
                                : _ImagePlaceholder(
                                    theme: theme,
                                    text: 'Tap to add a cover image',
                                  ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _EditFormSection(
              title: 'Event details',
              subtitle: 'Update the story and core details for volunteers.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Event title', null),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Category', null),
                    initialValue: _selectedCategory,
                    items: _categories
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) =>
                        setState(() => _selectedCategory = newValue),
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(18),
                    child: InputDecorator(
                      decoration: _inputDecoration('Date & time', null),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFF667085),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Select the date and starting time'
                                  : DateFormat('EEE, MMM d, y - h:mm a').format(
                                      _selectedDate!,
                                    ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _selectedDate == null
                                    ? AppColors.disabled
                                    : AppColors.textPrimary,
                                fontWeight: _selectedDate == null
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: _inputDecoration('Description', null),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a description'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _EditFormSection(
              title: 'Location',
              subtitle: 'Keep the meetup point accurate for volunteers.',
              child: EventLocationPicker(
                initialValue: _selectedLocation,
                onChanged: (value) {
                  _selectedLocation = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            _EditFormSection(
              title: 'Preparation',
              subtitle: 'Fine-tune what volunteers should bring or expect.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _carryController,
                    decoration: _inputDecoration(
                      'Things to carry',
                      'Gloves, water bottle, cap',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _providedController,
                    decoration: _inputDecoration(
                      'Things provided',
                      'Trash bags, tools, refreshments',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _EditFormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _EditFormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ThemeData theme;
  final String text;

  const _ImagePlaceholder({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 200 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.08;
        final showHelperText =
            constraints.maxHeight >= 170 &&
            MediaQuery.textScalerOf(context).scale(1) < 1.2;

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 20,
              vertical: compact ? 12 : 18,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 46 : 54,
                      height: compact ? 46 : 54,
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(compact ? 14 : 16),
                      ),
                      child: Icon(
                        Icons.photo_camera_back_outlined,
                        color: AppColors.primary,
                        size: compact ? 20 : 24,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: (compact
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                    ),
                    if (showHelperText && text == 'Tap to add a cover image') ...[
                      SizedBox(height: compact ? 4 : 6),
                      Text(
                        'Landscape images work best for discovery cards.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: (compact
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
