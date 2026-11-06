import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class CustomAppSliverGridView extends StatelessWidget {
  const CustomAppSliverGridView({
    super.key,
    this.children,
    this.axisDirection = Axis.vertical,
    this.maxPerRow = 2,
    this.minWidth = 300,
  });
  final List<Widget>? children;
  final Axis axisDirection;
  final int maxPerRow;
  final double minWidth;
  @override
  Widget build(BuildContext context) {
    return ResponsiveSliverGridList(
      horizontalGridSpacing: 20.h, // Horizontal space between grid items
      verticalGridSpacing: 16, // Vertical space between grid items
      horizontalGridMargin: 12.h, // Horizontal space around the grid
      verticalGridMargin: 5, // Vertical space around the grid
      minItemWidth:
          minWidth, // The minimum item width (can be smaller, if the layout constraints are smaller)
      minItemsPerRow:
          maxPerRow, // The minimum items to show in a single row. Takes precedence over minItemWidth
      maxItemsPerRow:
          maxPerRow, // The maximum items to show in a single row. Can be useful on large screens
      sliverChildBuilderDelegateOptions:
          SliverChildBuilderDelegateOptions(), // Options that are getting passed to the SliverChildBuilderDelegate() function
      children: [...?children], // The list of widgets in the list
    );
  }
}
