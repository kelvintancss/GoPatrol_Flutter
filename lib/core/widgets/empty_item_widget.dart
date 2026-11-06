import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';

class EmptyItemWidget extends StatelessWidget {
  const EmptyItemWidget({
    super.key,
    this.content,
    this.title,
    this.imgPath,
    this.icon,
    this.iconSize,
    this.iconColor,
  });
  final String? title;
  final String? content;
  final String? imgPath;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          (kBottomNavigationBarHeight * 2).ph,
          if (imgPath != null)
            Image.asset(imgPath!, width: 100.w, height: 100.h, fit: BoxFit.contain)
          else
            Icon(
              icon,
              size: iconSize ?? 60,
              color: iconColor ?? Colors.grey.shade400,
            ),
          10.ph,
          if (title?.isNotEmpty ?? false) title!.titleWithoutBoldText(),
          10.ph,
          if (content?.isNotEmpty ?? false)
            content!.bodyText(
              color: AppColor.textGrey,
              maxLine: 5,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
