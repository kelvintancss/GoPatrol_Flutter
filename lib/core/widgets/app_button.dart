import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';

/// Custom Big button widget
class PrimaryAppButton extends StatelessWidget {
  const PrimaryAppButton({
    super.key,
    required this.title,
    this.onTap,
    this.height,
    this.width,
    this.bgColor,
    this.borderColor,
    this.borderSize,
    this.evelation,
  });
  final String title;
  final VoidCallback? onTap;
  final double? height, width, borderSize;
  final Color? bgColor;
  final Color? borderColor;
  final double? evelation;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: evelation ?? 0,
        backgroundColor: bgColor ?? AppColor.primary,
        minimumSize: Size(width ?? 80.w, height ?? 45.h),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor ?? AppColor.primary),
          borderRadius: BorderRadius.circular(borderSize ?? 10),
        ),
      ),
      onPressed: onTap,
      child: title.buttonText(
        color: bgColor != null ? AppColor.primary : Colors.white,
      ),
    );
  }
}

class CustomAppButton extends StatelessWidget {
  const CustomAppButton({
    super.key,
    required this.title,
    this.onTap,
    this.height,
    this.minSize,
    this.bgColor,
    this.borderSize,
    this.evelation,
    this.fontSize,
    this.textColor,
  });
  final String title;
  final VoidCallback? onTap;
  final double? height, minSize, borderSize;
  final Color? bgColor;
  final double? evelation;
  final double? fontSize;
  final Color? textColor;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: evelation ?? 0,
        backgroundColor: bgColor ?? AppColor.primary,
        minimumSize: Size(minSize ?? 80.w, height ?? 43.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderSize ?? 12),
        ),
      ),
      onPressed: onTap,
      child: title.buttonText(
        color: textColor ?? Colors.white,
        textAlign: TextAlign.center,
        fontSize: fontSize,
        maxLine: 10,
      ),
    );
  }
}

/// Custom Seconadry button widget
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.title,
    this.onTap,
    this.height,
    this.minSize,
    this.bgColor,
    this.borderColor,
    this.borderSize,
    this.evelation,
    this.fontSize,
  });
  final String title;
  final VoidCallback? onTap;
  final double? height, minSize, borderSize;
  final Color? bgColor;
  final Color? borderColor;
  final double? evelation;
  final double? fontSize;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        elevation: evelation ?? 0,
        backgroundColor: bgColor,
        minimumSize: minSize != null
            ? Size(minSize ?? 80.w, height ?? 45.h)
            : null,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor ?? AppColor.primary),
          borderRadius: BorderRadius.circular(borderSize ?? 12),
        ),
        side: BorderSide(color: borderColor ?? AppColor.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      ),
      onPressed: onTap,
      child: title.buttonText(
        color: borderColor ?? AppColor.primary,
        fontSize: fontSize,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class FillButton extends StatelessWidget {
  const FillButton({
    super.key,
    required this.title,
    this.onTap,
    this.height,
    this.minSize,
    this.bgColor,
    this.borderColor,
    this.borderSize,
    this.evelation,
    this.fontSize,
  });
  final String title;
  final VoidCallback? onTap;
  final double? height, minSize, borderSize;
  final Color? bgColor;
  final Color? borderColor;
  final double? evelation;
  final double? fontSize;
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        elevation: evelation ?? 0,
        backgroundColor: bgColor,
        minimumSize: minSize != null
            ? Size(minSize ?? 80.w, height ?? 45.h)
            : null,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor ?? AppColor.primary),
          borderRadius: BorderRadius.circular(borderSize ?? 12),
        ),
        side: BorderSide(color: borderColor ?? AppColor.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      ),
      onPressed: onTap,
      child: title.buttonText(
        color: borderColor,
        fontSize: fontSize,
        textAlign: TextAlign.center,
      ),
    );
  }
}
