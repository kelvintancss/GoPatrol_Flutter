import 'package:flutter/material.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';

/// One checkpoint of a shift route. [isNext] highlights the checkpoint the
/// user must scan next; [isDone] dims checkpoints already scanned.
class PatrolRouteCard extends StatelessWidget {
  const PatrolRouteCard({
    super.key,
    required this.item,
    this.isNext = false,
    this.isDone = false,
  });

  final PatrolShiftRouteItem item;
  final bool isNext;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final formName = item.digitalForm?.formName ?? '';
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
        side: BorderSide(
          color: isNext ? AppColor.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: isNext
              ? AppColor.primary.withValues(alpha: 0.08)
              : AppColor.white,
          borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  'Checkpoint: ${item.scanCode}'.bodyWithBoldText(
                    fontSize: 15,
                    maxLine: 1,
                    color: isDone ? AppColor.darkGrey : null,
                  ),
                  6.ph,
                  (item.checkpointRemark.isNotEmpty
                          ? item.checkpointRemark
                          : '-')
                      .smallText(color: AppColor.textGrey, maxLine: 2),
                  4.ph,
                  '${item.timeStart}  ~  ${item.timeEnd}'
                      .smallText(color: AppColor.textGrey),
                  4.ph,
                  'Form: ${formName.isNotEmpty ? formName : '-'}'
                      .smallText(color: AppColor.textGrey, maxLine: 1),
                ],
              ),
            ),
            if (isNext)
              'Next'.smallTextWithBold(color: AppColor.primary)
            else if (isDone)
              const Icon(Icons.check_circle, color: AppColor.primary),
          ],
        ),
      ),
    );
  }
}
