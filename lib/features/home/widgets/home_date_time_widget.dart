import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/icon_widget.dart';
import 'package:patrol/gen/assets.gen.dart';
import 'package:patrol/service_locator.dart';

class HomeDateTimeWidget extends StatefulWidget {
  const HomeDateTimeWidget({super.key});

  @override
  State<HomeDateTimeWidget> createState() => _HomeDateTimeWidgetState();
}

class _HomeDateTimeWidgetState extends State<HomeDateTimeWidget> {
  late DateTime currentTime;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    currentTime = DateTime.now();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _nextSyncLabel() {
    final nextSyncAt = sl<PatrolHomeDataManager>().nextSyncAt.value;
    var remaining = nextSyncAt?.difference(currentTime) ?? Duration.zero;
    if (remaining.isNegative) remaining = Duration.zero;
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '(Next Sync: $minutes:$seconds)';
  }

  @override
  Widget build(BuildContext context) {
    String day = DateFormat('EEEE').format(currentTime);
    String date = DateFormat('dd MMMM yyyy').format(currentTime);
    String time = DateFormat('HH:mm').format(currentTime.toLocal());
    return Row(
      spacing: 10.w,
      children: [
        IconWidget(imgPath: Assets.images.facilityBooking.path, height: 30.h),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                "$day, ".titleWithoutBoldText(fontSize: 18.sp),
                date.titleWithoutBoldText(fontSize: 18.sp),
              ],
            ),
            5.ph,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                time.titleBoldText(fontSize: 22.sp),
                8.pw,
                Text(
                  _nextSyncLabel(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.italic,
                    color: AppColor.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
