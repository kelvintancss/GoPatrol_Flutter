import 'package:flutter/material.dart';

ThemeData buildTheme() {
  final baseTheme = lightTheme;
  return baseTheme;
}

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColor.primary,
  scaffoldBackgroundColor: AppColor.white,
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColor.white,
  ),
  checkboxTheme: CheckboxThemeData(
    overlayColor: WidgetStateProperty.all<Color>(AppColor.primary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusGeometry.circular(5),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColor.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.grey),
  dividerTheme: const DividerThemeData(color: AppColor.lightGrey),
  colorScheme: const ColorScheme.light(
    primary: AppColor.primary,
    secondary: AppColor.primary,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColor.primary,
    linearTrackColor: Colors.transparent,
  ),
  radioTheme: RadioThemeData(
    splashRadius: 0,
    innerRadius: WidgetStatePropertyAll(0),
    side: BorderSide(),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStatePropertyAll(AppColor.grey),
    trackOutlineColor: WidgetStatePropertyAll(AppColor.grey),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blueGrey,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.grey),
  dividerTheme: DividerThemeData(color: AppColor.lightGrey),
  colorScheme: ColorScheme.dark(
    primary: AppColor.primary,
    secondary: AppColor.primary,
  ),
);

class AppColor {
  const AppColor._();

  static const Color primary = Color(0xFF24AD4A);
  static const Color secondary = Color(0xFF16682C);
  static const Color midnightGreen = Color(0xFF012626);
  static const Color lightGreen = Color(0xFF4DFF7F);
  static const Color lushGreen = Color(0xFF04BF62);
  static const Color slateGreen = Color(0xFF367368);
  static const Color mintGreen = Color(0xFF51A687);
  static const Color textGrey = Color(0xFF666666);
  static const Color hintGrey = Color(0xFF808080);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color deepGreen = Color(0xFF1C6930);
  static const Color darkGrey = Color(0xFF999999);
  static const Color slightlyDarkGrey = Color(0xFFDCDCDC);
  static const Color deepLavenderGrey = Color(0xFF6F6B7A);
  static const Color disabledBackgroundColor = Color(0xFFE0E0E0);
  static const Color deepGrey = Color.fromARGB(38, 102, 102, 102);

  static const Color dangerRed = Color.fromARGB(253, 212, 51, 51);
  static const Color deepRed = Color(0xFFB71C1C);

  static const Color white = Color(0xFFFFFBFF);

  static const Color deepBlue = Color(0xFF252545);
  static const Color brown = Color(0xFF7E631E);
  static const Color mainYellow = Color(0xFFFCC63D);
  static const Color lightYellow = Color(0xFFFEE39E);
  static const Color grey = Color(0xFF999999);
  static const Color pendingOrange = Color(0xFFF7B924); //0xFFFA8900
}
