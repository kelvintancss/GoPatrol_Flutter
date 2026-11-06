import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';

class IncidentLogCard extends StatelessWidget {
  const IncidentLogCard({super.key, required this.entry, required this.onTap});

  final IncidentLogEntry entry;
  final VoidCallback onTap;

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
              Icon(
                Icons.report_gmailerrorred,
                color: AppColor.dangerRed,
                size: 28.sp,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4.h,
                  children: [
                    Row(
                      spacing: 8.w,
                      children: [
                        Flexible(
                          child: entry.cssLoginCode.mediumTextWithBold(),
                        ),
                        '|'.smallText(color: AppColor.textGrey),
                        Flexible(
                          child: formatPatrolLogDate(entry.dateInput)
                              .smallText(color: AppColor.textGrey),
                        ),
                      ],
                    ),
                    entry.formName.bodyText(),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColor.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
