import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/core/utils/utils.dart';

/// For error navigation
class ErrorRouteWidget extends StatelessWidget {
  const ErrorRouteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            context.loc.generalErrorMsg.bodyWithBoldText(
              textAlign: TextAlign.center,
            ),
            10.ph,
            GestureDetector(
              onTap: () => context.go(AppRouter.home),
              child: context.loc.goBack.bodyWithBoldText(),
            ),
          ],
        ),
      ),
    );
  }
}
