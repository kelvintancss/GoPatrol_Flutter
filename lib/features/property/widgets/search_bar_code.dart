import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';

class SearchBarCode extends StatelessWidget {
  SearchBarCode({
    super.key,
    this.prefix,
    this.isEnable = true,
    this.callback,
    this.isAutoFocus = false,
    this.padding = 0,
    this.hintText,
    this.showBarCode = true,
    this.onChanged,
    this.scanCode,
    this.textInputType,
    this.textInputAction,
    this.onSubmitted,
    this.controller,
    this.onClickSearch,
    this.focusNode,
    this.bgColor,
    this.borderColor,
    this.showSearchIcon = true,
    this.hintColor,
  });
  final Widget? prefix;
  final bool isEnable;
  final Function()? callback;
  final bool isAutoFocus;
  final double padding;
  final String? hintText;
  final bool showBarCode;
  final Function(String value)? onChanged;
  final Function()? scanCode;
  final TextInputType? textInputType;
  final TextInputAction? textInputAction;
  final Function(String value)? onSubmitted;
  final TextEditingController? controller;
  final Function()? onClickSearch;
  final FocusNode? focusNode;
  final Color? bgColor;
  final Color? borderColor;
  final bool showSearchIcon;
  final Color? hintColor;

  final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColor.deepGrey, width: 1),
  );

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor != null
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor!, width: 1),
          )
        : _border;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: GestureDetector(
        onTap: callback,
        child: SizedBox(
          height: 40.h,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: isEnable,
            autofocus: isAutoFocus,
            onTapOutside: (event) => FocusScope.of(context).unfocus(),
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            textInputAction: textInputAction,
            keyboardType: textInputType,
            decoration: InputDecoration(
              hintText: hintText ?? context.loc.searchHint,
              hintStyle: TextStyle(
                color: hintColor ?? Colors.grey,
                fontSize: 14.sp,
                fontWeight: FontWeight.normal,
              ),
              filled: bgColor != null,
              fillColor: bgColor ?? Colors.white,
              border: effectiveBorder,
              enabledBorder: effectiveBorder,
              focusedBorder: effectiveBorder,
              contentPadding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
              isDense: showBarCode,
              suffixIconConstraints: BoxConstraints(
                minHeight: 18.h,
                minWidth: 18.h,
              ),
              prefixIcon: showBarCode
                  ? GestureDetector(
                      onTap: scanCode,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: AppColor.deepGrey,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                              child: Image.asset(
                                'assets/images/scan_color_main_green.png',
                                height: 20.h,
                                width: 20.h,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Scan",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    )
                  : null,
              suffixIcon: showSearchIcon
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: onClickSearch,
                        child: Image.asset(
                          'assets/images/search_color_grey.png',
                          height: 18.h,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
