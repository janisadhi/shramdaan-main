import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../../auth/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser;
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  DateTime? _selectedDob;
  String? _selectedGender;
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: (widget.userData['displayName'] as String?)?.trim().isNotEmpty == true
          ? (widget.userData['displayName'] as String).trim()
          : (widget.currentUser.displayName ?? ''),
    );
    _emailController = TextEditingController(
      text: widget.currentUser.email ?? '',
    );
    _phoneController = TextEditingController(
      text: (widget.userData['phoneNumber'] as String?)?.trim() ?? '',
    );
    final dobRaw = widget.userData['dob'];
    if (dobRaw is Timestamp) {
      _selectedDob = dobRaw.toDate();
    }
    _selectedGender = (widget.userData['gender'] as String?)?.trim().isNotEmpty == true
        ? (widget.userData['gender'] as String).trim()
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile == null) {
        return;
      }
      final imageBytes = await pickedFile.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingImageBytes = imageBytes;
        _pendingImageName = pickedFile.name;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open your gallery. Please allow photo access and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _pickDob() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDob = pickedDate;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? photoUrl;
      if (_pendingImageBytes != null && _pendingImageName != null) {
        photoUrl = await _firestoreService.uploadProfilePicture(
          imageBytes: _pendingImageBytes!,
          userId: widget.currentUser.uid,
          fileName: _pendingImageName!,
        );
        if (photoUrl == null || photoUrl.isEmpty) {
          throw Exception('Profile photo upload failed.');
        }
      }

      await _firestoreService.updateUserProfile(
        userId: widget.currentUser.uid,
        displayName: trimmedName,
        photoUrl: photoUrl,
        phoneNumber: _phoneController.text.trim(),
        dob: _selectedDob,
        gender: _selectedGender,
      );

      await _authService.updateUserAuthProfile(
        displayName: trimmedName,
        photoURL: photoUrl,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update your profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPhotoUrl =
        (widget.userData['photoUrl'] as String?)?.trim().isNotEmpty == true
        ? (widget.userData['photoUrl'] as String).trim()
        : widget.currentUser.photoURL;

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _pendingImageBytes != null
                                  ? Image.memory(
                                      _pendingImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : currentPhotoUrl != null && currentPhotoUrl.isNotEmpty
                                  ? ShramdaanNetworkImage(
                                      imageUrl: currentPhotoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: Container(
                                        color: Colors.white,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 40,
                                          color: AppColors.disabled,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 40,
                                        color: AppColors.disabled,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _pickImage,
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('Change photo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Your name',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '98XXXXXXXX',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        hintText: 'Select gender',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                        DropdownMenuItem(
                          value: 'Prefer not to say',
                          child: Text('Prefer not to say'),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _isSaving ? null : _pickDob,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of birth',
                          hintText: 'Select date of birth',
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDob == null
                                    ? 'Select date of birth'
                                    : DateFormat.yMMMMd().format(_selectedDob!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _selectedDob == null
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
