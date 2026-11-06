import 'package:flutter/material.dart';

class CustomScrollWidget extends StatelessWidget {
  const CustomScrollWidget({
    super.key,
    this.child = const [],
    this.controller,
    this.onRefresh,
  });
  final List<Widget> child;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh ?? () async {}, // Your refresh logic
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [...child],
      ),
    );
  }
}
