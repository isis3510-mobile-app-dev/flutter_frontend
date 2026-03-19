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
    final hasAttachments = attachments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.labelAdditionalFiles,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
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
                color: AppColors.primaryVariant,
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
                          color: AppColors.primary,
                          size: 48,
                        ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.uploadDocuments,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.grey700,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onRemoveAttachment == null
                          ? null
                          : () => onRemoveAttachment!(index),
                      icon: const Icon(Icons.close_rounded),
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
