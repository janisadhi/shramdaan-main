import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/event_location_picker.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _carryController = TextEditingController();
  final _providedController = TextEditingController();
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
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

  Future<void> _submitForm() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedCategory == null ||
        _selectedLocation == null ||
        currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete the required fields and choose an event location.',
          ),
        ),
      );
      return;
    }

    if (_imageBytes == null || _imageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a cover image for the event.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final imageUrl = await _firestoreService.uploadImage(
      imageBytes: _imageBytes!,
      fileName: _imageName!,
    );
    if (imageUrl == null || imageUrl.isEmpty) {
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

    final thingsToCarry = _carryController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final thingsProvided = _providedController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await _firestoreService.addEvent(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _selectedLocation!.formattedAddress,
      formattedAddress: _selectedLocation!.formattedAddress,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      eventDate: _selectedDate!,
      category: _selectedCategory!,
      organizerId: currentUser.uid,
      organizerName: currentUser.displayName ?? 'Anonymous',
      imageUrl: imageUrl,
      thingsToCarry: thingsToCarry,
      thingsProvided: thingsProvided,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Add Post'),
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
            onPressed: _isLoading ? null : _submitForm,
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
                : const Icon(Icons.check_circle_outline),
            label: Text(_isLoading ? 'Publishing...' : 'Submit for Review'),
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
                    'Create a Shramdaan',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share the cause, set the meeting point, and send it for admin review.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _HeroHint(
                          icon: Icons.schedule_outlined,
                          label: 'Pick a date',
                        ),
                        SizedBox(width: 8),
                        _HeroHint(
                          icon: Icons.location_on_outlined,
                          label: 'Set a location',
                        ),
                        SizedBox(width: 8),
                        _HeroHint(
                          icon: Icons.rate_review_outlined,
                          label: 'Send for review',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FormSection(
              title: 'Cover image',
              subtitle: 'Choose a strong visual from your device.',
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
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact =
                                      constraints.maxHeight < 200 ||
                                      MediaQuery.textScalerOf(context).scale(1) >
                                          1.08;
                                  final showHelperText =
                                      constraints.maxHeight >= 170 &&
                                      MediaQuery.textScalerOf(context).scale(1) <
                                          1.2;

                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 16 : 20,
                                        vertical: compact ? 12 : 18,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 220,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: compact ? 46 : 54,
                                                height: compact ? 46 : 54,
                                                decoration: BoxDecoration(
                                                  color: AppColors.infoSoft,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    compact ? 14 : 16,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .photo_camera_back_outlined,
                                                  color: AppColors.primary,
                                                  size: compact ? 20 : 24,
                                                ),
                                              ),
                                              SizedBox(
                                                height: compact ? 10 : 12,
                                              ),
                                              Text(
                                                'Tap to upload a cover image',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: (compact
                                                        ? theme
                                                            .textTheme.titleSmall
                                                        : theme.textTheme
                                                            .titleMedium)
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors
                                                          .textPrimary,
                                                      height: 1.15,
                                                    ),
                                              ),
                                              if (showHelperText) ...[
                                                SizedBox(
                                                  height: compact ? 4 : 6,
                                                ),
                                                Text(
                                                  'Landscape images work best for discovery cards.',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: (compact
                                                          ? theme.textTheme
                                                              .bodySmall
                                                          : theme.textTheme
                                                              .bodyMedium)
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .textSecondary,
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
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Event details',
              subtitle: 'Tell volunteers what the activity is about.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Event title', 'Bagmati River Clean-Up Drive'),
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
                    decoration: _inputDecoration(
                      'Description',
                      'What will volunteers do, who should join, and what impact will this event have?',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a description'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Location',
              subtitle: 'Drop a pin or search for the exact meetup point.',
              child: EventLocationPicker(
                initialValue: _selectedLocation,
                onChanged: (value) {
                  _selectedLocation = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Preparation',
              subtitle: 'Optional details that help volunteers arrive ready.',
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

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FormSection({
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

class _HeroHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroHint({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
