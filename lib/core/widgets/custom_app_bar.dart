import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/widgets/app_button_rounded.dart';
import 'package:patrol/core/widgets/icon_widget.dart';
import 'package:patrol/gen/assets.gen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.customHeight,
    this.centerTitle,
    this.backgroundColor,
    this.automaticallyImplyLeading,
    this.isMainPage = false,
    this.flexiSpace,
    this.leadingWidth,
    this.titleSpacing,
    this.foregroundColor,
  });
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double? customHeight;
  final bool? centerTitle;
  final Color? backgroundColor;
  final bool? automaticallyImplyLeading;
  final bool isMainPage;
  final Widget? flexiSpace;
  final double? leadingWidth;
  final double? titleSpacing;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      centerTitle: centerTitle ?? true,
      leading:
          leading ??
          (automaticallyImplyLeading == false
              ? null
              : const AppBackButtonWidget()),
      actions: [...?actions, 15.pw],
      leadingWidth: leadingWidth ?? 70.w,
      titleSpacing: titleSpacing,
      backgroundColor: isMainPage ? AppColor.deepGreen : backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      toolbarHeight: customHeight ?? AppBar().preferredSize.height,
      flexibleSpace: flexiSpace,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(customHeight ?? AppBar().preferredSize.height * 1.2);
}

class AppBackButtonWidget extends BackButton {
  const AppBackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AppButtonIcon(
      text: "", // not needed when using icon
      textColor: Colors.white,
      backgroundColor: AppColor.primary,
      borderColor: AppColor.primary,
      size: 50,
      icon: Icons.arrow_back,
      isIcon: true,
      onPressed: () => context.pop(),
    );
  }
}

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          10.pw,
          context.loc.goGuardManagementSystem.titleWithoutBoldText(
            color: Colors.white,
          ),
        ],
      ),
      leading: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        padding: EdgeInsets.only(left: 10.w),
        child: IconWidget(
          imgPath: Assets.images.goguardGrey.path,
          height: 80.h,
          width: 50.w,
          color: Colors.white,
        ),
      ),
      isMainPage: true,
      automaticallyImplyLeading: false,
      flexiSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColor.deepGreen, AppColor.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(AppBar().preferredSize.height * 1.2);
}
