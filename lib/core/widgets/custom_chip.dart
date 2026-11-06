import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';

class CustomChip extends StatelessWidget {
  const CustomChip({super.key, this.onTap, this.isSelected = false, this.title = '', this.hasLeftMargin = true});
  final Function()? onTap;
  final bool isSelected;
  final String title;
  final bool hasLeftMargin;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await HapticFeedback.lightImpact();
        onTap != null ? onTap!() : null;
      },
      child: Container(
        alignment: Alignment.center,
        margin: hasLeftMargin ? const EdgeInsets.fromLTRB(10, 8, 3, 8) : null,
        decoration: BoxDecoration(
            color: isSelected ? AppColor.primary : null,
            borderRadius: BorderRadius.circular(30),
            border: Border.fromBorderSide(BorderSide(color: isSelected ? AppColor.primary : AppColor.textGrey))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: isSelected
            ? title.bodyWithBoldText(color: AppColor.white)
            : title.bodyText(
                color: AppColor.textGrey,
              ),
      ),
    );
  }
}
