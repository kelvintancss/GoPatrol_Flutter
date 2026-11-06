import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/sheet_modal.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

import 'app_button.dart';

class CustomDialog {
  static bool _isDialogShowing = false;
  static bool get isDialogShowing => _isDialogShowing;

  static showAppToast(String msg) {
    EasyThrottle.throttle(
      'first-toast', // <-- An ID for this particular debouncer
      const Duration(milliseconds: 500),
      () => MyDialog.toast(msg),
    );
  }

  static showAppDialog(String msg, {bool Function()? onConfirm, bool barrierDismissible = true, String title = 'CSS GoGuard'}) {
    EasyThrottle.throttle('dialog', const Duration(milliseconds: 500), () {
      MyDialog.alert(
        (msg.isNotEmpty ? msg : getContext!.loc.generalErrorMsg).bodyText(maxLine: 3, textAlign: TextAlign.center),
        titleWidget: Align(alignment: Alignment.topCenter, child: title.bodyWithBoldText()),
        onConfirm: onConfirm,
        buttonStyle: TextStyle(color: Colors.white, fontSize: 13.sp),
        style: ModalStyle(
          titlePadding: const EdgeInsets.only(top: 15),
          textBodyAlignment: CrossAxisAlignment.center,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Constants.borderRadiusLarge)),
          actionsPadding: const EdgeInsets.all(0),
          expandedAction: true,
          clipBehavior: Clip.hardEdge,
          primaryButtonStyle: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            elevation: 0,
            backgroundColor: AppColor.primary,
          ),
        ),
        buttonText: MyDialog.navigatorKey.currentContext?.loc.okLabel,
        barrierDismissible: barrierDismissible,
      );
    });
  }

  static Future showDialogWithOption(
    BuildContext context, {
    String? title,
    String? desc,
    String? confirmText,
    String? cancelText,
    Future<bool> Function()? confirmCallback,
  }) async {
    return await MyDialog.confirm(
      desc,
      titleWidget: Align(
        alignment: Alignment.topCenter,
        child: (title ?? "CSS GoGuard").bodyWithBoldText(textAlign: TextAlign.center),
      ),
      onConfirm: confirmCallback,
      buttonText: confirmText,
      cancelText: cancelText,
      buttonStyle: TextStyle(color: AppColor.dangerRed, fontSize: 13.sp),
      cancelStyle: TextStyle(fontSize: 13.sp),
      style: ModalStyle.separated(
        contentTextStyle: Theme.of(context).textTheme.bodyLarge,
        textBodyAlignment: CrossAxisAlignment.center,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Constants.borderRadiusLarge)),
        separator: const BorderSide(color: AppColor.darkGrey),
      ),
    );
  }

  static Future<void> showConfirmDialog(String msg, {Function()? onConfirm, bool barrierDismissible = true}) async {
    EasyThrottle.throttle('dialog', const Duration(milliseconds: 500), () async {
      await MyDialog.alertModal(
        barrierDismissible: barrierDismissible,
        Container(
          alignment: Alignment.center,
          child: Column(children: ["CSS GoGuard".bodyWithBoldText(), 3.ph, (msg).bodyText(maxLine: 10)]),
        ),
        [CustomAppButton(title: getContext?.loc.okLabel ?? "Okay", onTap: onConfirm)],
        style: const ModalStyle(actionsAlignment: MainAxisAlignment.center),
      );
    });
  }

  static showAppWithImageDialog(String msg, {String? title, bool Function()? onConfirm, bool barrierDismissible = true, String imgPath = ''}) {
    EasyThrottle.throttle('dialog', const Duration(milliseconds: 500), () {
      MyDialog.alert(
        (msg.isNotEmpty ? msg : getContext!.loc.generalErrorMsg).bodyText(maxLine: 3, textAlign: TextAlign.center),
        titleWidget: Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              (title ?? 'GoGuard').bodyWithBoldText(),
              const SizedBox(height: 10),
              if (imgPath.isNotEmpty) Image.asset(imgPath, height: 100.h, width: 100.w),
            ],
          ),
        ),
        onConfirm: onConfirm,
        buttonStyle: const TextStyle(color: Colors.white),
        style: ModalStyle(
          titlePadding: const EdgeInsets.only(top: 15),
          contentTextStyle: "".bodyText(color: AppColor.textGrey).style,
          textBodyAlignment: CrossAxisAlignment.center,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Constants.borderRadiusLarge)),
          actionsSeparator: const BorderSide(color: AppColor.lightGrey),
          actionsPadding: const EdgeInsets.all(0),
          expandedAction: true,
          clipBehavior: Clip.hardEdge,
          primaryButtonStyle: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            elevation: 0,
            backgroundColor: AppColor.primary,
          ),
        ),
        buttonText: MyDialog.navigatorKey.currentContext?.loc.okLabel,
      );
    });
  }

  static showSelectBtmSheet(BuildContext context, {required List<(String value, String label)> filter, Function(String value, String label)? onTap}) {
    showBtmSheet(
      context,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(Constants.appPaddingMedium),
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Constants.appPadding),
            itemBuilder: (context, index) {
              final e = filter[index];
              return GestureDetector(
                onTap: () {
                  onTap?.call(e.$1, e.$2);
                  context.pop();
                },
                child: e.$2.bodyText(),
              );
            },
            separatorBuilder: (context, index) => Divider(height: 30.h),
            itemCount: filter.length,
          ),
        ),
      ),
    );
  }

  static showSelectDynamicTypeBtmSheet(
    BuildContext context, {
    required List<(dynamic value, dynamic label)> filter,
    Function(dynamic value, dynamic label)? onTap,
  }) {
    showBtmSheet(
      context,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(Constants.appPaddingMedium),
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: const EdgeInsets.all(Constants.appPadding),
            itemBuilder: (context, index) {
              final e = filter[index];
              return GestureDetector(
                onTap: () {
                  onTap?.call(e.$1, e.$2);
                  context.pop();
                },
                child: (e.$2 as String?)?.bodyText(),
              );
            },
            separatorBuilder: (context, index) => Divider(height: 30.h),
            itemCount: filter.length,
          ),
        ),
      ),
    );
  }

  static Future showDialogImageWithOption(
    BuildContext context, {
    String? title,
    String? desc,
    String? confirmText,
    String? cancelText,
    Future<bool> Function()? confirmCallback,
    String imgPath = '',
    Widget? bodyWidget,
    bool? barrierDismissible,
  }) async {
    return await MyDialog.confirm(
      '',
      titleWidget: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            (title ?? "CSS Goguard").bodyWithBoldText(),
            const SizedBox(height: 10),
            if (imgPath.isNotEmpty) Image.asset(imgPath, height: 100.h, width: 100.w),
            (desc ?? "").bodyText(),
            if (bodyWidget != null) ...[15.ph, bodyWidget],
          ],
        ),
      ),
      onConfirm: confirmCallback,
      buttonText: confirmText,
      barrierDismissible: barrierDismissible,
      cancelText: cancelText,
      cancelStyle: TextStyle(fontSize: 15.sp),
      buttonStyle: TextStyle(color: AppColor.dangerRed, fontSize: 13.sp),
      style: ModalStyle.separated(
        contentTextStyle: Theme.of(context).textTheme.bodyMedium,
        textBodyAlignment: CrossAxisAlignment.center,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Constants.borderRadiusLarge)),
        separator: const BorderSide(color: AppColor.darkGrey),
      ),
    );
  }

  static Future<dynamic> showAppDialogWithIcon(
    Widget? msg, {
    bool Function()? onConfirm,
    bool? barrierDismissible,
    String? confirmText,
    Color? btnColor,
    bool withClose = false,
  }) async {
    return await MyDialog.alert(
      SizedBox(width: double.maxFinite, child: msg),
      onConfirm: onConfirm,
      buttonStyle: const TextStyle(color: Colors.white),
      withClose: withClose ,
      style: ModalStyle(
        titlePadding: const EdgeInsets.only(top: 20),
        textBodyAlignment: CrossAxisAlignment.center,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Constants.borderRadiusLarge)),
        actionsPadding: const EdgeInsets.all(0),
        expandedAction: true,
        clipBehavior: Clip.hardEdge,
        primaryButtonStyle: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          elevation: 0,
          backgroundColor: btnColor ?? AppColor.primary,
        ),
      ),
      buttonText: confirmText ?? MyDialog.navigatorKey.currentContext?.loc.okLabel,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<dynamic> showNetworkConnectionLost({int count = 0}) async {
    if (getContext?.loaderOverlay.visible == true) {
      getContext?.loaderOverlay.hide();
    }
    if (_isDialogShowing) {
      getContext?.pop();
      _isDialogShowing = false;
    }
    _isDialogShowing = true;
    return await MyDialog.alertModal(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, color: AppColor.deepRed, size: 50.h),
          15.ph,
          "Connection Lost".bodyWithBoldText(color: AppColor.deepRed),
          "Retry count $count".mediumText(textAlign: TextAlign.center),
        ],
      ),
      [],
      barrierDismissible: true,
    );
  }

  static Future<dynamic> showNetworkRetryDialog() async {
    if (getContext?.loaderOverlay.visible == true) {
      getContext?.loaderOverlay.hide();
    }
    if (_isDialogShowing) {
      getContext?.pop();
      _isDialogShowing = false;
    }
    _isDialogShowing = true;
    return await showAppDialogWithIcon(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, color: AppColor.deepRed, size: 50.h),
          15.ph,
          "Connection Lost".bodyWithBoldText(color: AppColor.deepRed),
        ],
      ),
      onConfirm: () {
        return true;
      },
      confirmText: "Retry",
      barrierDismissible: true,
    );
  }

  static dismissDialogShow() => _isDialogShowing = false;
  static BuildContext? get getContext => MyDialog.navigatorKey.currentContext;
}
