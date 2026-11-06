import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';

class CheckpointCard extends StatelessWidget {
  const CheckpointCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  final PatrolCheckpointEntry entry;

  /// Null when the checkpoint has no digital form — the card isn't tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
          ),
          child: Row(
            spacing: 10.w,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 8.w,
                      children: [
                        Flexible(
                          child: entry.displayCode
                              .bodyWithBoldText(fontSize: 16),
                        ),
                        if (entry.isSkip) const _SkipTag(),
                      ],
                    ),
                    if (entry.formName.isNotEmpty) ...[
                      4.ph,
                      'Form: ${entry.formName}'
                          .smallText(color: AppColor.primary, maxLine: 1),
                    ],
                    4.ph,
                    DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(entry.timestamp)
                        .smallText(color: AppColor.textGrey),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColor.darkGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipTag extends StatelessWidget {
  const _SkipTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.pendingOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Constants.borderRadiusSmall),
        border: Border.all(color: AppColor.pendingOrange),
      ),
      child: 'SKIP'.smallTextWithBold(color: AppColor.pendingOrange),
    );
  }
}
