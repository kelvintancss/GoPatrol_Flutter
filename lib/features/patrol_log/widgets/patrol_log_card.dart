import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';

class PatrolLogCard extends StatelessWidget {
  const PatrolLogCard({super.key, required this.entry, required this.onTap});

  final PatrolLogEntry entry;
  final VoidCallback onTap;

  /// Scanned / total checkpoints — green when the route is complete.
  Widget _buildProgress() {
    final done = entry.routeCount >= entry.totalRouteCount;
    final color = done ? AppColor.deepGreen : AppColor.pendingOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Constants.borderRadiusSmall),
        border: Border.all(color: color),
      ),
      child: '${entry.routeCount}/${entry.totalRouteCount}'
          .smallTextWithBold(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
          ),
          child: Row(
            spacing: 10.w,
            children: [
              Icon(Icons.nfc, color: AppColor.deepGreen, size: 20.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8.h,
                  children: [
                    (entry.shiftName.isNotEmpty
                            ? entry.shiftName
                            : entry.cssLoginCode)
                        .mediumTextWithBold(),
                    if (entry.shiftName.isNotEmpty)
                      [
                        entry.cssLoginCode,
                        if (entry.calendarDay.isNotEmpty) entry.calendarDay,
                      ].join(' · ').smallText(),
                    '${formatPatrolLogDate(entry.startDate)} ~ '
                            '${formatPatrolLogDate(entry.endDate)}'
                        .smallText(color: AppColor.textGrey),
                  ],
                ),
              ),
              if (entry.totalRouteCount > 0) _buildProgress(),
              Icon(Icons.chevron_right, color: AppColor.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
