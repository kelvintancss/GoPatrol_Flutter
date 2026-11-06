import 'package:flutter/material.dart';

class ErrorImageWidget extends StatelessWidget {
  /// Created for cachednetwork package
  /// encounter Internet or internal issues cant load image
  /// here widget to handle
  const ErrorImageWidget({super.key, this.backgroundColor, this.boxShape});
  final Color? backgroundColor;
  final BoxShape? boxShape;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: boxShape != null ? null : BorderRadius.circular(10),
        shape: boxShape ?? BoxShape.rectangle,
      ),
      alignment: Alignment.center,
      child: Image.asset("assets/images/goguard-grey.png"),
    );
  }
}
