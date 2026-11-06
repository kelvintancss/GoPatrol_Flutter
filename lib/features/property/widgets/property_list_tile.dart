import 'package:custom_network_image/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/core/widgets/icon_widget.dart';

class PropertyListTile extends StatelessWidget {
  final String projectId;
  final String projectName;
  final bool isSelected;
  final Function()? onTap;
  final String imgUrl;
  final double? btmPadding;

  const PropertyListTile({
    super.key,
    this.projectId = "-",
    this.projectName = "-",
    this.isSelected = false,
    this.onTap,
    this.imgUrl = "",
    this.btmPadding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () => context.push(
            context.namedLocation(
              AppRouter.loginName,
              queryParameters: {
                "projectId": projectId,
                "projectName": projectName,
              },
            ),
          ),
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColor.primary) : null,
        ),
        margin: EdgeInsets.only(bottom: btmPadding ?? Constants.appPadding),
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Flexible(
                  child: Visibility(
                    visible: imgUrl.isEmpty,
                    replacement: CustomCachedImageWidget(
                      imgUrl: imgUrl,
                      boxFit: BoxFit.fill,
                      customShape: BoxShape.circle,
                      height: 40.h,
                      width: 40.w,
                    ),
                    child: IconWidget(
                      imgPath: 'assets/images/property.png',
                      height: 32.h,
                      width: 32.w,
                    ),
                  ),
                ),
                20.pw,
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      context.loc.propertyName.smallText(
                        color: AppColor.textGrey,
                        fontSize: 10.sp,
                      ),
                      (projectName).mediumText(maxLine: 2),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: -16,
              top: -15.h,
              child: Visibility(
                visible: isSelected,
                child: CircleAvatar(
                  radius: 10.h,
                  backgroundColor: AppColor.primary,
                  child: const IconWidget(
                    imgPath: 'assets/images/checked_color_white.png',
                    height: 11,
                    width: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
