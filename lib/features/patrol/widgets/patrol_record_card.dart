import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';

class PatrolRecordCard extends StatelessWidget {
  const PatrolRecordCard({super.key, required this.record, required this.onTap});

  final PatrolRecordHeader record;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (record.syncStatus) {
      case 'pending':
        return AppColor.pendingOrange;
      case 'fail':
        return AppColor.dangerRed;
      case 'partial':
        return Colors.deepOrange;
      case 'success':
        return Colors.cyan;
      default:
        return AppColor.primary;
    }
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10.w,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    record.uuid.bodyWithBoldText(fontSize: 14, maxLine: 1),
                    6.ph,
                    '${record.startDate}  ~  ${record.endDate}'
                        .smallText(color: AppColor.textGrey),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(Constants.borderRadiusSmall),
                  border: Border.all(color: _statusColor),
                ),
                child: record.syncStatus.smallText(color: _statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
