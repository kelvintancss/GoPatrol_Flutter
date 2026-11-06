import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/patrol/widgets/patrol_route_card.dart';

/// Read-only view of the active shift's route as stored in SQLite (no API
/// call). [nextIndex] is highlighted; earlier checkpoints show as done.
class PatrolShiftRouteDialog extends StatelessWidget {
  const PatrolShiftRouteDialog({
    super.key,
    required this.shift,
    required this.route,
    required this.nextIndex,
  });

  final PatrolActiveShift shift;
  final PatrolShiftRoute? route;
  final int nextIndex;

  static Future<void> show(
    BuildContext context, {
    required PatrolActiveShift shift,
    required PatrolShiftRoute? route,
    required int nextIndex,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PatrolShiftRouteDialog(
        shift: shift,
        route: route,
        nextIndex: nextIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = route?.routes ?? const <PatrolShiftRouteItem>[];
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.75.sh),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              'Shift Route'.titleBoldText(color: Colors.black),
              12.ph,
              shift.shiftName.bodyWithBoldText(maxLine: 1),
              4.ph,
              '${shift.timeStart}  ~  ${shift.timeEnd}'
                  .smallText(color: AppColor.textGrey),
              if (route != null && route!.version.isNotEmpty) ...[
                4.ph,
                'Version: ${route!.version}'
                    .smallText(color: AppColor.textGrey),
              ],
              10.ph,
              if (routes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: 'No route available for this shift.'.bodyText(
                    textAlign: TextAlign.center,
                    color: AppColor.textGrey,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: routes.length,
                    separatorBuilder: (context, index) => 8.ph,
                    itemBuilder: (context, index) => PatrolRouteCard(
                      item: routes[index],
                      isNext: index == nextIndex,
                      isDone: index < nextIndex,
                    ),
                  ),
                ),
              15.ph,
              CustomAppButton(
                title: 'Close',
                bgColor: AppColor.darkGrey,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
