import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/core/widgets/sheet_modal.dart';
import 'package:patrol/features/property/cubit/property_cubit.dart';
import 'package:patrol/gen/assets.gen.dart';

class PropertyPage extends StatefulWidget {
  const PropertyPage({super.key});

  @override
  State<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  void goSearchPage({bool isOpenScan = false}) {
    context.read<PropertyCubit>().resetProperty();
    context.pushNamed(AppRouter.searchPropertyName, extra: {'isOpenScan': isOpenScan});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: Colors.transparent,
        title: context.loc.myPropertyTitle.titleBoldText(color: Colors.white),
        isMainPage: true,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'property',
        shape: const CircleBorder(),
        tooltip: context.loc.linkPropertyTitle,
        backgroundColor: AppColor.primary,
        onPressed: () {
          showBtmSheet(
            context,
            child: Container(
              padding: const EdgeInsets.all(Constants.appPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Image.asset(Assets.images.scanColorMainGreen.path),
                    title: context.loc.scanPropertyCode.bodyWithBoldText(),
                    onTap: () {
                      context.pop();
                      goSearchPage(isOpenScan: true);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Image.asset(Assets.images.searchColorMainGreen.path),
                    title: context.loc.searchByPropertyCode.bodyWithBoldText(),
                    onTap: () {
                      context.pop();
                      goSearchPage();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const IconWidget(imgPath: 'assets/images/add_color_white.png'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Constants.appPaddingMedium),
          child: Column(
            children: [
              EmptyItemWidget(imgPath: Assets.images.appIcon.path, title: context.loc.propertyLinkNow, content: context.loc.propertyLinkEmptyDesc),
              25.ph,
              AppButtonRounded(
                onTap: () {
                  goSearchPage();
                },
                btnText: context.loc.linkNowLabel,
                btnWidth: 300.w,
                btnColor: AppColor.primary,
              ),
              16.ph,
              LanguageDropdown(width: 300.w),
            ],
          ),
        ),
      ),
    );
  }
}
