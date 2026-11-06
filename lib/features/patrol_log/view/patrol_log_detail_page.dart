import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';

/// Shows a patrol session's checkpoints straight from its `route_list` —
/// no API call needed.
class PatrolLogDetailPage extends StatelessWidget {
  const PatrolLogDetailPage({super.key, required this.entry});

  final PatrolLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final routes = entry.routeList;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Patrol Detail'.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: routes.isEmpty
            ? const EmptyItemWidget(
                icon: Icons.nfc,
                title: 'No patrol detail',
                content: 'This patrol session has no checkpoints.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(15.0),
                itemCount: routes.length + 1,
                separatorBuilder: (context, index) => 10.ph,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader();
                  return _RouteCard(route: routes[index - 1]);
                },
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        (entry.shiftName.isNotEmpty ? entry.shiftName : entry.cssLoginCode)
            .bodyWithBoldText(color: Colors.black),
        4.ph,
        '${formatPatrolLogDate(entry.startDate)} ~ '
                '${formatPatrolLogDate(entry.endDate)}'
            .bodyText(textAlign: TextAlign.center),
        5.ph,
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final PatrolLogRoute route;

  @override
  Widget build(BuildContext context) {
    // `scanded == 1` rows are highlighted red.
    final highlight = route.scanned;
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: highlight
              ? AppColor.white: AppColor.dangerRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
          border: Border.all(
            color: highlight ? Colors.transparent : AppColor.dangerRed,
          ),
        ),
        child: Row(
          spacing: 10.w,
          children: [
            Icon(
              Icons.nfc,
              color: highlight ? AppColor.deepGreen : AppColor.dangerRed,
              size: 20.sp,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6.h,
                children: [
                  route.scanCode.mediumTextWithBold(),
                  if (route.remark.isNotEmpty) route.remark.smallText(),
                  (route.checkDate.isNotEmpty
                          ? formatPatrolLogDate(route.checkDate)
                          : '-')
                      .smallText(color: AppColor.textGrey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
