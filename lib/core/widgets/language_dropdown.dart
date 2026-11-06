import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/utils/locale_controller.dart';

class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.notifier,
      builder: (context, locale, _) {
        return Container(
          width: width ?? 300.w,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: locale.languageCode,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: _LanguageDropdownItem(flag: '🇬🇧', label: 'English'),
                ),
                DropdownMenuItem(
                  value: 'ms',
                  child: _LanguageDropdownItem(flag: '🇲🇾', label: 'Bahasa Melayu'),
                ),
              ],
              onChanged: (code) {
                if (code != null) LocaleController.setLocale(code);
              },
            ),
          ),
        );
      },
    );
  }
}

class _LanguageDropdownItem extends StatelessWidget {
  const _LanguageDropdownItem({required this.flag, required this.label});

  final String flag;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: TextStyle(fontSize: 17.sp)),
        8.pw,
        Text(label, style: TextStyle(fontSize: 17.sp)),
      ],
    );
  }
}
