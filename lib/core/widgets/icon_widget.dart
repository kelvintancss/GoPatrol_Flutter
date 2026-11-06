import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IconWidget extends StatelessWidget {
  const IconWidget({
    super.key,
    required this.imgPath,
    this.height = 30,
    this.width = 30,
    this.onTap,
    this.semanticLabel,
    this.boxFit,
    this.color,
  });
  final String imgPath;
  final double height;
  final double width;
  final Function()? onTap;
  final String? semanticLabel;
  final BoxFit? boxFit;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imgPath,
        height: height.h,
        width: width.w,
        fit: boxFit,
        semanticLabel: semanticLabel,
        color: color,
      ),
    );
  }
}
