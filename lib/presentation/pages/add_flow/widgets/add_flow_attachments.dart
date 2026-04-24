import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/attachment_models.dart';

class AddFlowAttachmentsSection extends StatelessWidget {
  const AddFlowAttachmentsSection({
    super.key,
    this.onTap,
    this.attachments = const <AttachmentUploadItem>[],
    this.onRemoveAttachment,
    this.onRetryAttachment,
  });

  final VoidCallback? onTap;
  final List<AttachmentUploadItem> attachments;
  final ValueChanged<String>? onRemoveAttachment;
  final ValueChanged<String>? onRetryAttachment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAttachments = attachments.isNotEmpty;
    final hasPendingUploads = attachments.any(
      (attachment) => attachment.isPending,
    );
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
            onTap: hasPendingUploads ? null : onTap,
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
                  hasPendingUploads
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
                    hasPendingUploads
                        ? 'Uploading...'
                        : AppStrings.uploadDocuments,
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
            final attachment = attachments[index];
            final status = _statusMetadata(attachment.status, isDark: isDark);
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
                    Icon(status.icon, size: 18, color: status.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: attachmentText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: status.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (attachment.errorMessage != null &&
                              attachment.errorMessage!.trim().isNotEmpty)
                            Text(
                              attachment.errorMessage!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: helperColor,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (attachment.isFailed && onRetryAttachment != null)
                      IconButton(
                        onPressed: () => onRetryAttachment!(attachment.localId),
                        icon: Icon(Icons.refresh_rounded, color: helperColor),
                        tooltip: 'Retry attachment',
                      ),
                    IconButton(
                      onPressed: onRemoveAttachment == null
                          ? null
                          : () => onRemoveAttachment!(attachment.localId),
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

class _AttachmentStatusMetadata {
  const _AttachmentStatusMetadata({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

_AttachmentStatusMetadata _statusMetadata(
  AttachmentUploadStatus status, {
  required bool isDark,
}) {
  final successColor = isDark ? AppColors.positiveTextDark : AppColors.success;
  final warningColor = isDark
      ? AppColors.smartAlertWarningTextDark
      : AppColors.warning;
  final errorColor = isDark ? AppColors.negativeTextDark : AppColors.error;

  return switch (status) {
    AttachmentUploadStatus.queued => _AttachmentStatusMetadata(
      icon: Icons.schedule_rounded,
      color: warningColor,
      label: 'Queued',
    ),
    AttachmentUploadStatus.processing => _AttachmentStatusMetadata(
      icon: Icons.tune_rounded,
      color: warningColor,
      label: 'Preparing',
    ),
    AttachmentUploadStatus.uploading => _AttachmentStatusMetadata(
      icon: Icons.cloud_upload_outlined,
      color: warningColor,
      label: 'Uploading',
    ),
    AttachmentUploadStatus.succeeded => _AttachmentStatusMetadata(
      icon: Icons.check_circle_outline_rounded,
      color: successColor,
      label: 'Uploaded',
    ),
    AttachmentUploadStatus.failed => _AttachmentStatusMetadata(
      icon: Icons.error_outline_rounded,
      color: errorColor,
      label: 'Failed',
    ),
  };
}
