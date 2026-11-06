import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/features/patrol/view/patrol_digital_form_page.dart';

/// Renders submitted digital form [items] (answers in `formValue` /
/// `formItemGroupList`) without any way to change them.
class ReadOnlyDigitalForm extends StatelessWidget {
  const ReadOnlyDigitalForm({super.key, required this.items});

  final List<PatrolFormItem> items;

  static const _groupItem = 'formItemGroupItem';
  static const _groupItemValue = 'formItemGroupItemValue';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _buildItem(item),
          ),
      ],
    );
  }

  Widget _buildTitle(PatrolFormItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.labelText.isNotEmpty) item.labelText.bodyWithBoldText(),
        if (item.groupName.isNotEmpty) ...[
          4.ph,
          item.groupName.smallText(color: AppColor.textGrey),
        ],
      ],
    );
  }

  Widget _buildValueBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColor.lightGrey.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(Constants.borderRadiusSmall),
        border: Border.all(color: AppColor.lightGrey),
      ),
      child: (value.isEmpty ? '-' : value).bodyText(maxLine: 9999),
    );
  }

  /// One option row with a non-interactive radio/checkbox indicator.
  Widget _buildOption(Map<String, dynamic> option, {required bool radio}) {
    final selected = option[_groupItemValue] == true;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        spacing: 10.w,
        children: [
          if (radio)
            RadioDot(selected: selected)
          else
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 22.sp,
              color: selected ? AppColor.primary : AppColor.textGrey,
            ),
          Expanded(
            child: (option[_groupItem]?.toString() ?? '').bodyText(),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(PatrolFormItem item) {
    switch (item.typeId) {
      case 'HEADER':
        return item.pageHeaderText.titleBoldText();
      case 'TEXT':
      case 'EMAIL':
      case 'SHORT TEXT':
      case 'LONG TEXT':
      case 'INTEGER':
      case 'DECIMAL':
      case 'DATETIME':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8.h,
          children: [
            _buildTitle(item),
            _buildValueBox(item.formValue ?? ''),
          ],
        );
      case 'SINGLE CHOICE':
      case 'MULTIPLE CHOICE':
        final radio = item.typeId == 'SINGLE CHOICE';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(item),
            4.ph,
            ...item
                .decodeGroupList()
                .map((option) => _buildOption(option, radio: radio)),
          ],
        );
      case 'DROPDOWN':
        final selected = item
            .decodeGroupList()
            .firstWhereOrNull((e) => e[_groupItemValue] == true)?[_groupItem]
            ?.toString();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8.h,
          children: [
            _buildTitle(item),
            _buildValueBox(selected ?? ''),
          ],
        );
      case 'NOTES':
        return Align(
          alignment: Alignment.topLeft,
          child: (item.formValue ?? '').bodyText(maxLine: 9999),
        );
      case 'LOGO':
        final url = item.fileUrl;
        if (url == null || url.isEmpty) return const SizedBox.shrink();
        return Image.network(
          url,
          height: 200.h,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      default:
        // ATTACHMENT photos are shown by the caller; TERMSANDCONDITIONS
        // etc. aren't supported here yet.
        return const SizedBox.shrink();
    }
  }
}
