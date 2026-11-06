import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'error/error_image_widget.dart';

class CustomCachedImageWidget extends StatelessWidget {
  const CustomCachedImageWidget({
    super.key,
    required this.imgUrl,
    this.height,
    this.width,
    this.alignment,
    this.boxFit,
    this.colorFilter,
    this.customShape,
    this.customBorder,
    this.customBorderRadius,
    this.hasNormalBorder = false,
    this.isNormalRounded = false,
    this.useOldImgUrl = false,
    this.bgColor = Colors.white
  });

  final String imgUrl;
  final double? height;
  final double? width;
  final Alignment? alignment;
  final BoxFit? boxFit;
  final ColorFilter? colorFilter;
  final BoxShape? customShape;
  final BoxBorder? customBorder; // For custom border
  final BorderRadiusGeometry? customBorderRadius; // For custom rounded corner
  final bool hasNormalBorder; // For general border
  final bool isNormalRounded; // For general rounded corner
  final bool useOldImgUrl;
  final Color bgColor;
  @override
  Widget build(BuildContext context) {
    var normalBorder =
        const Border.fromBorderSide(BorderSide(color: Colors.grey));
    var normalBorderRadius = BorderRadius.circular(10);
    try {
      return CachedNetworkImage(
        imageUrl: imgUrl,
        useOldImageOnUrlChange: useOldImgUrl,
        color: bgColor,
        imageBuilder: (context, imageProvider) => Container(
          height: height,
          width: width,
          alignment: alignment,
          decoration: BoxDecoration(
            color: bgColor,
            shape: customShape ?? BoxShape.rectangle,
            border: customBorder ?? (hasNormalBorder ? normalBorder : null),
            borderRadius: customBorderRadius ??
                (isNormalRounded ? normalBorderRadius : null),
            image: DecorationImage(
              colorFilter: colorFilter,
              image: imageProvider,
              fit: boxFit ?? BoxFit.contain,
            ),
          ),
        ),
        errorWidget: (context, _, error) => SizedBox(
          height: height,
          width: width,
          child: ErrorImageWidget(
            boxShape: customShape,
          ),
        ),
        placeholder: (context, _) => SizedBox(
          height: height,
          width: width,
          child: ErrorImageWidget(
            boxShape: customShape,
          ),
        ),
      );
    } catch (e) {
      return SizedBox(
        height: height,
        width: width,
        child: const ErrorImageWidget(),
      );
    }
  }
}
