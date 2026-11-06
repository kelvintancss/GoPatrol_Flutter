import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';

class AppButtonRounded extends StatelessWidget {
  final VoidCallback? onTap;
  final double? btnWidth;
  final double? btnHeight;
  final String btnText;
  final Color? btnTextColor;
  final Color? btnColor;
  final double? fontSize;

  const AppButtonRounded({
    super.key,
    this.onTap,
    this.btnWidth,
    this.btnHeight,
    required this.btnText,
    this.btnTextColor = Colors.white,
    this.btnColor = AppColor.primary,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(btnWidth ?? 80.w, btnHeight ?? 48.h),
        backgroundColor: btnColor,
        foregroundColor: btnTextColor,
        elevation: 2.0,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
      ),
      child: Center(
        child: Text(
          btnText,
          style: TextStyle(
            fontSize: fontSize?.sp ?? 14.sp,
            fontWeight: FontWeight.w600,
            color: btnTextColor,
          ),
        ),
      ),
    );
  }
}

class AppButtonOutlined extends StatelessWidget {
  final VoidCallback? onTap;
  final double? btnWidth;
  final double? btnHeight;
  final String btnText;
  final Color? btnTextColor;
  final Color? borderColor;
  final double? borderSize;
  final double? fontSize;

  const AppButtonOutlined({
    super.key,
    this.onTap,
    this.btnWidth,
    this.btnHeight,
    required this.btnText,
    this.btnTextColor,
    this.borderColor = AppColor.primary,
    this.borderSize = 30,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = btnTextColor ?? borderColor ?? AppColor.primary;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        fixedSize: Size(btnWidth ?? 80.w, btnHeight ?? 48.h),
        side: BorderSide(color: borderColor ?? AppColor.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderSize!.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        elevation: 0,
      ),
      child: Center(
        child: Text(
          btnText,
          style: TextStyle(
            fontSize: fontSize?.sp ?? 14.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class AppButtonIcon extends StatelessWidget {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final String text;
  final VoidCallback? onPressed;
  final double size;
  final IconData? icon;
  final bool? isIcon;

  const AppButtonIcon({
    super.key,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.text,
    this.onPressed,
    required this.size,
    this.icon,
    this.isIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      splashColor: Colors.white.withValues(alpha: 0.3),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isIcon == false
              ? Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(icon, color: textColor, size: size * 0.5),
        ),
      ),
    );
  }
}

class AppButtonWithIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData? icon;
  final String btnText;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  const AppButtonWithIcon({
    super.key,
    this.onTap,
    this.icon,
    required this.btnText,
    this.backgroundColor = const Color(0xFF00C853),
    this.textColor = Colors.white,
    this.height = 45,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        height: height?.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 12.sp),
              SizedBox(width: 10.w),
            ],
            Text(
              btnText,
              style: TextStyle(
                color: textColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
