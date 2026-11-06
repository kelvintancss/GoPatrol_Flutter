import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/gen/assets.gen.dart';

class FacilityLogCard extends StatelessWidget {
  const FacilityLogCard({super.key, required this.entry});

  final FacilityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10.h,
          children: [
            Row(
              spacing: 5.w,
              children: [
                IconWidget(imgPath: Assets.images.myPropertyListIcon.path),
                entry.lotNo.mediumTextWithBold(),
              ],
            ),
            Row(
              spacing: 5.w,
              children: [
                IconWidget(imgPath: Assets.images.visitor.path),
                Expanded(child: entry.contactName.mediumText()),
              ],
            ),
            Row(
              spacing: 5.w,
              children: [
                IconWidget(imgPath: Assets.images.facilityBooking.path),
                Expanded(child: entry.facility.mediumText()),
              ],
            ),
            if ((entry.bookingTimeIn?.isNotEmpty ?? false) ||
                (entry.bookingTimeOut?.isNotEmpty ?? false))
              Row(
                spacing: 5.w,
                children: [
                  if (entry.bookingTimeIn?.isNotEmpty ?? false) ...[
                    IconWidget(imgPath: Assets.images.checkIn.path),
                    entry.bookingTimeIn!.mediumText(),
                  ],
                  if (entry.bookingTimeOut?.isNotEmpty ?? false) ...[
                    const Spacer(),
                    IconWidget(imgPath: Assets.images.checkedColorGreen.path),
                    entry.bookingTimeOut!.mediumText(),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
