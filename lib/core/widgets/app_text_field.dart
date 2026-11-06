import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/gen/assets.gen.dart';
import 'package:remove_emoji/remove_emoji.dart';

typedef PhoneCodeCallback = void Function();

final _border = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: const BorderSide(color: AppColor.lightGrey, width: 1),
);

const _padding = EdgeInsets.fromLTRB(0, 0, 0, 0);

class EmojiFilterFormatter extends TextInputFormatter {
  final _remover = RemoveEmoji();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final cleaned = _remover.clean(newValue.text);

    if (cleaned == newValue.text) {
      return newValue;
    }

    final int diff = newValue.text.length - cleaned.length;
    final int newOffset = (newValue.selection.baseOffset - diff).clamp(
      0,
      cleaned.length,
    );

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );
  }
}

/// @author hew
/// app text field utilieis
/// split to [isMobile] true - for mobile field with dial code
/// by default use normal
/// any update should you consider either both
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onTap,
    this.validator,
    this.keyboardType,
    this.isObscure = false,
    this.focusNode,
    this.isFocus,
    this.hasMargin = false,
    this.isEnable,
    this.isMobile = false,
    this.phoneCodeCallback,
    this.selectionPhoneCode,
    this.moreThanOneLine = false,
    this.showDropdown = false,
    this.dropItem,
    this.filter,
    this.onDropChanged,
    this.initialValue,
    this.line,
    this.autofocus = false,
    this.prefixText,
    this.isMust = false,
    this.bgColor,
    this.readOnly = false,
    this.maxLength,
    this.borderColor,
    this.height,
    this.textStyle,
    this.dropdownTextStyle,
    this.stripEmojis = false,
  });
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Function(String)? onChanged;
  final Function()? onTap;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isObscure;
  final FocusNode? focusNode;
  final ValueNotifier<bool>? isFocus;
  final bool hasMargin;
  final bool? isEnable;
  final bool isMobile;
  final PhoneCodeCallback? phoneCodeCallback;
  final String? selectionPhoneCode;
  final bool moreThanOneLine;
  final bool showDropdown;
  final String? dropItem;
  final List<DropdownMenuEntry>? filter;
  final ValueChanged<dynamic>? onDropChanged;
  final String? initialValue;
  final int? line;
  final bool autofocus;
  final String? prefixText;
  final bool isMust;
  final Color? bgColor;
  final bool readOnly;
  final int? maxLength;
  final Color? borderColor;
  final double? height;
  final TextStyle? textStyle;
  final TextStyle? dropdownTextStyle;
  final bool stripEmojis;

  @override
  Widget build(BuildContext context) {
    final _defaultTextStyle = "".mediumText().style;
    final _textStyle = textStyle ?? _defaultTextStyle;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<TextInputFormatter> inputFormatters = [
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      if (stripEmojis) EmojiFilterFormatter(),
    ];

    return GestureDetector(
      onTap: onTap ?? () => focusNode?.requestFocus(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
        margin: hasMargin
            ? const EdgeInsets.symmetric(horizontal: Constants.appPadding)
            : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? AppColor.deepGrey : bgColor,
          border: Border.fromBorderSide(
            BorderSide(
              color:
                  borderColor ??
                  (isFocus?.value == true
                      ? AppColor.primary
                      : isDarkMode
                      ? AppColor.deepGrey
                      : AppColor.lightGrey),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labelText != null)
              Row(
                children: [
                  labelText!.smallText(color: AppColor.textGrey),
                  if (isMust) " *".smallText(color: AppColor.dangerRed),
                ],
              ),
            isMobile
                ? SizedBox(
                    height: 28.h,
                    child: TextFormField(
                      focusNode: focusNode,
                      controller: controller,
                      obscureText: isObscure,
                      onChanged: onChanged,
                      style: _textStyle,
                      enabled: isEnable,
                      readOnly: readOnly,
                      inputFormatters: inputFormatters,
                      onTap: () {
                        if (isFocus != null) {
                          isFocus?.value = true;
                        }
                      },
                      onTapUpOutside: (e) {
                        if (isFocus != null) {
                          isFocus?.value = false;
                        }
                      },
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      validator: validator,
                      keyboardType: keyboardType ?? TextInputType.text,
                      textAlignVertical: const TextAlignVertical(y: -0.5),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hintText ?? '',
                        hintStyle: _textStyle?.copyWith(
                          color: AppColor.hintGrey,
                        ),
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: phoneCodeCallback,
                                child: Text(
                                  "+$selectionPhoneCode",
                                  style: _textStyle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            const SizedBox(
                              width: 10,
                              height: 25,
                              child: VerticalDivider(color: Colors.grey),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  )
                : !showDropdown
                ? SizedBox(
                    height: moreThanOneLine ? 70.h : height,
                    child: TextFormField(
                      initialValue: initialValue,
                      autofocus: autofocus,
                      focusNode: focusNode,
                      controller: controller,
                      obscureText: isObscure,
                      onChanged: onChanged,
                      enabled: isEnable,
                      readOnly: readOnly,
                      maxLines: moreThanOneLine ? 5 : line,
                      maxLength: maxLength,
                      inputFormatters: inputFormatters,
                      onTap: readOnly
                          ? onTap
                          : () {
                              if (isFocus != null) {
                                isFocus?.value = true;
                              }
                            },
                      onTapUpOutside: (e) {
                        if (isFocus != null) {
                          isFocus?.value = false;
                        }
                      },
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      validator: validator,
                      keyboardType: keyboardType ?? TextInputType.text,
                      style: _textStyle,
                      decoration: InputDecoration(
                        isDense: false,
                        prefixText: prefixText,
                        prefixStyle: _textStyle,
                        hintText: hintText ?? '',
                        hintStyle: _textStyle?.copyWith(
                          color: AppColor.hintGrey,
                        ),
                        prefixIcon: prefixIcon,
                        border: InputBorder.none,
                        suffixIcon: suffixIcon,
                        prefixIconConstraints: BoxConstraints(minHeight: 27.h),
                        suffixIconConstraints: BoxConstraints(minHeight: 27.h),
                      ),
                    ),
                  )
                : DropdownMenu(
                    dropdownMenuEntries:
                        filter?.map((entry) {
                          return DropdownMenuEntry<String>(
                            value: entry.value,
                            label: entry.label,
                            labelWidget: Padding(
                              padding: EdgeInsets.only(
                                right: 20.w,
                              ), // Adjust this value as needed
                              child: Text(
                                entry.label,
                                style:
                                    dropdownTextStyle ??
                                    textStyle ??
                                    _textStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: ButtonStyle(
                              textStyle: WidgetStatePropertyAll(
                                dropdownTextStyle ?? textStyle ?? _textStyle,
                              ),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 14.w),
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                          );
                        }).toList() ??
                        [],
                    controller: controller,
                    hintText: hintText,
                    initialSelection: initialValue,
                    width: double.maxFinite,
                    onSelected: onDropChanged,
                    textStyle: textStyle ?? _textStyle,
                    menuStyle: MenuStyle(
                      elevation: const WidgetStatePropertyAll(4),
                      maximumSize: WidgetStatePropertyAll(
                        Size(double.infinity, 300.h),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(
                          horizontal: 0,
                        ), // Remove menu padding
                      ),
                    ),
                    selectedTrailingIcon: Image.asset(
                      'assets/images/arrow_drop_down.png',
                      height: 15,
                      width: 15,
                    ),
                    trailingIcon: Image.asset(
                      'assets/images/arrow_drop_down.png',
                      height: 15,
                      width: 15,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: bgColor ?? Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 5.0,
                        horizontal: 5.0,
                      ),
                      hintStyle: textStyle?.copyWith(color: AppColor.hintGrey),
                      labelStyle: textStyle,
                      border: InputBorder.none,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
