import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/profile_photo_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String _profilePhotoValue = '';
  String? _localPhotoPath;
  Uint8List? _selectedPhotoBytes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _profilePhotoValue = widget.profile.profilePhoto;
    _loadStoredLocalPhotoPath();
  }

  Future<void> _loadStoredLocalPhotoPath() async {
    final photoPath = await _photoService.getLocalPhotoPath();
    if (!mounted || photoPath == null) {
      return;
    }

    setState(() {
      _localPhotoPath = photoPath;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _userService.updateCurrentUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        profilePhoto: '', // Don't send photo to backend (stored locally instead)
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSaveSuccess)),
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.profileSaveError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _requiredFieldValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return AppStrings.validationRequired;
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final requiredValidation = _requiredFieldValidator(value);
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final trimmed = value!.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return AppStrings.authErrorInvalidEmail;
    }

    return null;
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final extension = _extensionFromName(pickedFile.name);

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingPhoto = true;
        _errorMessage = null;
      });

      final photoPath = await _photoService.saveImageFileLocally(
        bytes: bytes,
        directoryName: 'profile_photos',
        fileNamePrefix: 'profile',
        extension: extension,
      );

      if (!mounted) {
        return;
      }

      // Save the photo path to SharedPreferences for persistence
      await _photoService.saveLocalPhotoPath(photoPath);

      setState(() {
        _localPhotoPath = photoPath;
        _selectedPhotoBytes = bytes;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.profilePhotoPickError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    await _photoService.clearLocalPhoto();
    setState(() {
      _profilePhotoValue = '';
      _localPhotoPath = null;
      _selectedPhotoBytes = null;
    });
  }

  String _extensionFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'png';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    if (lower.endsWith('.heic')) {
      return 'heic';
    }
    return 'jpg';
  }

  bool _isHttpImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  ImageProvider<Object>? _photoImageProvider() {
    // Priority 1: Newly selected photo bytes (in memory)
    if (_selectedPhotoBytes != null) {
      return MemoryImage(_selectedPhotoBytes!);
    }

    // Priority 2: Locally saved photo file
    if (_localPhotoPath != null && _localPhotoPath!.isNotEmpty) {
      return FileImage(File(_localPhotoPath!));
    }

    // Priority 3: Photo from backend (HTTPS URL)
    final trimmed = _profilePhotoValue.trim();
    if (_isHttpImageUrl(trimmed)) {
      return NetworkImage(trimmed);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = _photoImageProvider();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profileEditTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileFormField(
                  label: AppStrings.authFullName,
                  controller: _nameController,
                  validator: _requiredFieldValidator,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                _ProfileFormField(
                  label: AppStrings.profileEmail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                _ProfileFormField(
                  label: AppStrings.profilePhone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                _ProfileFormField(
                  label: AppStrings.profileAddress,
                  controller: _addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  AppStrings.profilePhoto,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: AppDimensions.iconXL,
                        backgroundColor: AppColors.grey100,
                        backgroundImage: photoProvider,
                        child: photoProvider == null
                            ? const Icon(
                                Icons.person_outline,
                                size: AppDimensions.iconL,
                                color: AppColors.grey700,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: (_isSaving || _isUploadingPhoto)
                                  ? null
                                  : _pickPhotoFromGallery,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                (_localPhotoPath == null || _localPhotoPath!.isEmpty) &&
                                    _profilePhotoValue.trim().isEmpty
                                    ? AppStrings.profileSelectFromGallery
                                    : AppStrings.profileChangePhoto,
                              ),
                            ),
                            if ((_localPhotoPath != null && _localPhotoPath!.isNotEmpty) ||
                                _profilePhotoValue.trim().isNotEmpty)
                              TextButton(
                                onPressed: (_isSaving || _isUploadingPhoto)
                                    ? null
                                    : _removePhoto,
                                child: const Text(AppStrings.profileRemovePhoto),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isUploadingPhoto) ...[
                  const SizedBox(height: AppDimensions.spaceS),
                  Row(
                    children: [
                      const SizedBox(
                        width: AppDimensions.iconS,
                        height: AppDimensions.iconS,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.spaceS),
                      Text(
                        AppStrings.profilePhotoUploading,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceL),
                Text(
                  AppStrings.profileReadOnlyGroupInfo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey700,
                      ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                _ReadOnlyCountTile(
                  label: AppStrings.profilePetsCount,
                  value: widget.profile.pets.length.toString(),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                _ReadOnlyCountTile(
                  label: AppStrings.profileFamilyGroupCount,
                  value: widget.profile.familyGroup.length.toString(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceL),
                SizedBox(
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: (_isSaving || _isUploadingPhoto)
                        ? null
                        : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: AppDimensions.iconS,
                            height: AppDimensions.iconS,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.profileSaveChanges),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFormField extends StatelessWidget {
  const _ProfileFormField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppDimensions.spaceS),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.secondary,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceM,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: BorderSide(
                color: AppColors.grey300,
                width: AppDimensions.strokeThin,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: BorderSide(
                color: AppColors.grey300,
                width: AppDimensions.strokeThin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: AppDimensions.strokeThin,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyCountTile extends StatelessWidget {
  const _ReadOnlyCountTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.grey700),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
