import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio_client/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:patrol/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Get localization context shortcut
extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}

/// Hash md5
extension SimpleHash on Object {
  String get hashMd5 => md5.convert(utf8.encode(toString())).toString();
}

extension EmptyPadding on num {
  SizedBox get ph => SizedBox(height: toDouble());

  SizedBox get pw => SizedBox(width: toDouble());

  /// Sliver empty space
  SliverToBoxAdapter get sph {
    return SliverToBoxAdapter(child: SizedBox(height: toDouble()));
  }

  Widget get dvd => Divider(height: toDouble(), color: AppColor.lightGrey);
}

// ignore: camel_case_types
typedef st = TextStyle;

extension StyledText on String {
  Text _textGeneralConfig({
    String text = '',
    double? fontSize,
    Color? color,
    TextAlign? textAlign,
    int? maxLine,
    TextDecoration? textDecoration,
    FontWeight? fontWeight,
    double? letterSpacing = 0.2,
    TextOverflow? textOverflow,
    String? fontFamily,
    Color? decorationColor,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLine,
      style: st(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        decoration: textDecoration,
        overflow: textOverflow,
        fontFamily: fontFamily,
        decorationColor: decorationColor,
      ),
    );
  }

  Text titleBoldText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 20.sp,
      textAlign: textAlign,
      maxLine: maxLine,
      fontWeight: FontWeight.bold,
      textDecoration: textDecoration,
    );
  }

  Text titleWithoutBoldText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 20.sp,
      textAlign: textAlign,
      maxLine: maxLine ?? 2,
      fontWeight: FontWeight.normal,
      textDecoration: textDecoration,
    );
  }

  Text bodyText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 16.sp,
      textAlign: textAlign,
      maxLine: maxLine ?? 2,
      fontWeight: FontWeight.normal,
      textDecoration: textDecoration,
    );
  }

  Text bodyWithBoldText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 16.sp,
      textAlign: textAlign,
      maxLine: maxLine ?? 2,
      fontWeight: FontWeight.bold,
      textDecoration: textDecoration,
    );
  }

  Text mediumText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 14.sp,
      textAlign: textAlign,
      maxLine: maxLine,
      fontWeight: FontWeight.normal,
      textDecoration: textDecoration,
    );
  }

  Text mediumTextWithBold({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 14.sp,
      textAlign: textAlign,
      maxLine: maxLine ?? 2,
      fontWeight: FontWeight.bold,
      textDecoration: textDecoration,
    );
  }

  Text mediumSecondaryText({double? fontSize, TextAlign? textAlign, int? maxLine, bool unlimitLine = false, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: AppColor.textGrey,
      fontSize: fontSize ?? 14.sp,
      textAlign: textAlign,
      maxLine: unlimitLine ? null : maxLine ?? 2,
      fontWeight: FontWeight.w400,
      textDecoration: textDecoration,
    );
  }

  Text smallText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 13.sp,
      textAlign: textAlign,
      maxLine: maxLine,
      fontWeight: FontWeight.normal,
      textDecoration: textDecoration,
    );
  }

  Text smallTextWithBold({
    double? fontSize,
    Color? color,
    TextAlign? textAlign,
    int? maxLine,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow,
  }) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 13.sp,
      textAlign: textAlign,
      maxLine: maxLine ?? 2,
      fontWeight: FontWeight.bold,
      textDecoration: textDecoration,
      textOverflow: textOverflow,
    );
  }

  Text smallButtonText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 13.sp,
      textAlign: textAlign,
      maxLine: maxLine ?? 2,
      fontWeight: FontWeight.w500,
      textDecoration: textDecoration,
    );
  }

  Text buttonText({double? fontSize, Color? color, TextAlign? textAlign, int? maxLine, TextDecoration? textDecoration}) {
    return _textGeneralConfig(
      text: toString(),
      color: color,
      fontSize: fontSize ?? 15.sp,
      textAlign: textAlign,
      maxLine: maxLine ?? 2,
      fontWeight: FontWeight.bold,
      textDecoration: textDecoration,
    );
  }
}

//  assets path handling
extension AssetPath on String {
  String get toNavPng => "assets/images/$this.png";
  String get toUserPng => "assets/images/$this.png";
  String get toSystemPng => "assets/images/$this.png";
  String get toListPng => "assets/images/$this.png";
  String get toMainFuncPng => "assets/images/$this.png";
}

/// Http response message
extension ProcessMessage on DioResponse {
  processCodeToMessage() {
    if (statusMessage == null) {
      return "${CustomDialog.getContext?.loc.generalErrorMsg ?? ""} (code:$statusCode)";
    }
    return "$statusMessage (code:$statusCode)";
  }
}

extension NavigatorExt on GoRouter {
  /// Performs a [GoRouter.of(context).pushNamedAndRemoveUntil] action with given [routeName]
  Future<dynamic> pushNamedAndRemoveUntil(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    while (canPop()) {
      pop();
    }
    pushReplacementNamed(name, pathParameters: pathParameters, queryParameters: queryParameters, extra: extra);
  }

  Future<dynamic> canPopOrGoInitial(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    print("can pop: ${canPop()}");
    go(name);
  }

  String get currLocation {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch ? lastMatch.matches : routerDelegate.currentConfiguration;
    final String location = matchList.uri.toString();
    return location;
  }
}

extension AddPadding on Widget {
  Widget pw({double value = Constants.appPaddingExtra}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: value),
      child: this,
    );
  }
}

extension DateTimeFormat on DateTime? {
  String? toDateTime() {
    if (this == null) return null;
    return this!.toIso8601String().split('T').first;
  }

  String toDateTime2() {
    if (this == null) return '';
    final formatter = DateFormat('yyyy-MM-dd, hh:mma');
    return formatter.format(this!);
  }

  String toDateWithDay() {
    if (this == null) return '';
    final formatter = DateFormat('dd MMMM yyyy');
    return formatter.format(this!);
  }

  String toDateTime3({bool isSplit = false}) {
    if (this == null) return '';
    final input = this?.toString();
    final date = this!;

    try {
      final isMidnight = date.hour == 0 && date.minute == 0 && date.second == 0;

      if (isMidnight) {
        final convertDate = DateTime.parse(input!.replaceAll(' ', 'T'));
        final formatter = DateFormat('yyyy-MM-dd');
        return formatter.format(convertDate);
      } else {
        if (isSplit) return DateFormat('yyyy-MM-dd \n hh:mma').format(date);
        return DateFormat('yyyy-MM-dd, hh:mma').format(date);
      }
    } catch (_) {
      return "";
    }
  }

  String toDateTime4() {
    if (this == null) return '';
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(this!);
  }
}

enum DayFilter { today, yesterday, last7day, last30day, last90day }

extension VmsRecurringType on String? {
  bool get isRecurring {
    if (this == null) return false;
    return this == Constants.visitorTypeRegularTransport || this == Constants.visitorTypeRegularVisitor;
  }
}
