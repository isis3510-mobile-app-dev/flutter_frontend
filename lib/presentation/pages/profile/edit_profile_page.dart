import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/forms/app_form_constraints.dart';
import 'package:flutter_frontend/core/forms/app_form_utils.dart';
import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/attachment_upload_service.dart';
import 'package:flutter_frontend/core/services/app_image_cache_manager.dart';
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
  final AttachmentUploadService _attachmentUploadService =
      AttachmentUploadService();
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String _profilePhotoValue = '';
  Map<String, dynamic> _pendingProfilePhotoSyncPayload =
      const <String, dynamic>{};
  Uint8List? _selectedPhotoBytes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _profilePhotoValue = widget.profile.profilePhoto;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    AppFormSanitizers.trimControllers([
      _nameController,
      _phoneController,
      _addressController,
    ]);

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
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        profilePhoto: _profilePhotoValue.trim(),
        profilePhotoSyncPayload: _pendingProfilePhotoSyncPayload,
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
    return AppFormValidators.required(
      AppStrings.validationFieldRequired(AppStrings.authFullName),
    )(value);
  }

  String? _phoneValidator(String? value) {
    return AppFormValidators.phone(
      maxLength: AppFormConstraints.phoneMaxLength,
      invalidMessage: AppStrings.validationPhoneInvalid,
    )(value);
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

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingPhoto = true;
        _errorMessage = null;
        _selectedPhotoBytes = bytes;
      });

      final uploadedPhoto = await _attachmentUploadService.uploadProfilePhoto(
        bytes: bytes,
        fileName: pickedFile.name,
        firebaseUid: widget.profile.firebaseUid,
      );

      debugPrint(
        '[EditProfilePage] uploaded profile photo url=${uploadedPhoto.downloadUrl}',
      );

      if (!mounted) {
        return;
      }

      if (uploadedPhoto.localFilePath != null &&
          uploadedPhoto.localFilePath!.trim().isNotEmpty) {
        await _photoService.saveLocalPhotoPath(uploadedPhoto.localFilePath!);
      } else {
        await _photoService.clearLocalPhoto();
      }

      final pendingProfilePhotoSyncPayload = uploadedPhoto.isPendingUpload
          ? <String, dynamic>{
              'profilePhotoPendingUpload': true,
              'profilePhotoStoragePath': uploadedPhoto.storagePath,
              'profilePhotoLocalFilePath': uploadedPhoto.localFilePath,
              'profilePhotoFileName': uploadedPhoto.fileName,
              'profilePhotoContentType': uploadedPhoto.contentType,
              'profilePhotoSizeBytes': uploadedPhoto.sizeBytes,
            }
          : const <String, dynamic>{};

      setState(() {
        _profilePhotoValue = uploadedPhoto.downloadUrl;
        _pendingProfilePhotoSyncPayload = pendingProfilePhotoSyncPayload;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedPhotoBytes = null;
        _errorMessage = '$error';
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
      _pendingProfilePhotoSyncPayload = const <String, dynamic>{};
      _selectedPhotoBytes = null;
    });
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

    // Priority 2: Photo from backend (HTTPS URL)
    final trimmed = _profilePhotoValue.trim();
    if (_isHttpImageUrl(trimmed)) {
      return CachedNetworkImageProvider(
        trimmed,
        cacheManager: AppImageCacheManager.instance,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoProvider = _photoImageProvider();
    final pageBackground = isDark
        ? AppColors.backgroundDark
        : AppColors.background;
    final cardBackground = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final helperTextColor = isDark ? AppColors.grey500 : AppColors.grey700;
    final avatarBackground = isDark ? AppColors.grey700 : AppColors.grey100;
    final avatarIconColor = isDark
        ? AppColors.onSurfaceDark
        : AppColors.grey700;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(title: const Text(AppStrings.profileEditTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileFormField(
                  label: AppStrings.authFullName,
                  controller: _nameController,
                  validator: _requiredFieldValidator,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      AppFormConstraints.personNameMaxLength,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),
                _ProfileFormField(
                  label: AppStrings.profilePhone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                  inputFormatters: AppInputFormatters.phone(),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                _ProfileFormField(
                  label: AppStrings.profileAddress,
                  controller: _addressController,
                  maxLines: 2,
                  validator: AppFormValidators.safeMultilineText(
                    fieldLabel: AppStrings.profileAddress,
                    maxLength: AppFormConstraints.addressMaxLength,
                  ),
                  inputFormatters: AppInputFormatters.safeMultilineText(
                    AppFormConstraints.addressMaxLength,
                  ),
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
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: AppDimensions.iconXL,
                        backgroundColor: avatarBackground,
                        backgroundImage: photoProvider,
                        child: photoProvider == null
                            ? Icon(
                                Icons.person_outline,
                                size: AppDimensions.iconL,
                                color: avatarIconColor,
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
                                _profilePhotoValue.trim().isEmpty &&
                                        _selectedPhotoBytes == null
                                    ? AppStrings.profileSelectFromGallery
                                    : AppStrings.profileChangePhoto,
                              ),
                            ),
                            if (_selectedPhotoBytes != null ||
                                _profilePhotoValue.trim().isNotEmpty)
                              TextButton(
                                onPressed: (_isSaving || _isUploadingPhoto)
                                    ? null
                                    : _removePhoto,
                                child: const Text(
                                  AppStrings.profileRemovePhoto,
                                ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: helperTextColor),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
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
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBackground = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;
    final enabledBorderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;
    final hintColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.55)
        : AppColors.grey700;

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
          inputFormatters: inputFormatters,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBackground,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: hintColor),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceM,
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: BorderSide(
                color: enabledBorderColor,
                width: AppDimensions.strokeThin,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: BorderSide(
                color: enabledBorderColor,
                width: AppDimensions.strokeThin,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: AppDimensions.strokeThin,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: AppDimensions.strokeThin,
              ),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimensions.radiusL),
              ),
              borderSide: BorderSide(
                color: AppColors.error,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBackground = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final iconColor = isDark ? AppColors.grey500 : AppColors.grey700;
    final textColor = isDark ? AppColors.onSurfaceDark : null;
    final valueColor = isDark ? AppColors.onSurfaceDark : AppColors.grey700;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: tileBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: iconColor),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
