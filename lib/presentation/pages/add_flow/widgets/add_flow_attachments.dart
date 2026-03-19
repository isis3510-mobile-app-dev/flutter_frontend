import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';

class AddFlowAttachmentsSection extends StatelessWidget {
  const AddFlowAttachmentsSection({
    super.key,
    this.onTap,
    this.attachments = const <String>[],
    this.onRemoveAttachment,
    this.isUploading = false,
  });

  final VoidCallback? onTap;
  final List<String> attachments;
  final ValueChanged<int>? onRemoveAttachment;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAttachments = attachments.isNotEmpty;
    final titleColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;
    final uploadBackground = isDark
        ? AppColors.quickActionIconBackgroundDark
        : AppColors.primaryVariant;
    final uploadTextColor = isDark
        ? AppColors.primaryVariant
        : AppColors.primary;
    final helperColor = isDark ? AppColors.grey500 : AppColors.grey700;
    final attachmentBackground = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;
    final attachmentBorder = isDark ? AppColors.grey700 : AppColors.grey300;
    final attachmentText = isDark
        ? AppColors.onSurfaceDark
        : AppColors.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.labelAdditionalFiles,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: InkWell(
            onTap: isUploading ? null : onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: uploadBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary, width: 1.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isUploading
                      ? const SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.file_upload_outlined,
                          color: uploadTextColor,
                          size: 48,
                        ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.uploadDocuments,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: uploadTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            AppStrings.uploadHint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: helperColor,
            ),
          ),
        ),
        if (hasAttachments) ...[
          const SizedBox(height: 14),
          ...List.generate(attachments.length, (index) {
            final fileName = attachments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: attachmentBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: attachmentBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                      color: helperColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: attachmentText),
                      ),
                    ),
                    IconButton(
                      onPressed: onRemoveAttachment == null
                          ? null
                          : () => onRemoveAttachment!(index),
                      icon: Icon(Icons.close_rounded, color: helperColor),
                      tooltip: 'Remove attachment',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
