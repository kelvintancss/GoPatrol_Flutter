import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/gen/assets.gen.dart';

class VisitorLogCard extends StatelessWidget {
  const VisitorLogCard({super.key, required this.entry, required this.onTap});

  final VisitorLogEntry entry;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10.h,
            children: [
              Row(
                spacing: 5.w,
                children: [
                  IconWidget(imgPath: Assets.images.myPropertyListIcon.path),
                  entry.lotNo.mediumTextWithBold(),
                  const Spacer(),
                  if (entry.overstay)
                    IconWidget(
                      imgPath: Assets.images.warningColorRed.path,
                      height: 18,
                      width: 18,
                    ),
                  Icon(Icons.chevron_right, color: AppColor.textGrey),
                ],
              ),
              Row(
                spacing: 5.w,
                children: [
                  IconWidget(imgPath: Assets.images.visitor.path),
                  Expanded(child: entry.visitorName.mediumText()),
                ],
              ),
              Row(
                spacing: 5.w,
                children: [
                  IconWidget(imgPath: Assets.images.checkIn.path),
                  Expanded(
                    child: (entry.checkInDate ?? '-').mediumText(),
                  ),
                  if (entry.overstay)
                    'Overstay'.mediumTextWithBold(color: AppColor.dangerRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
