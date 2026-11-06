import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';

class PatrolRecordDetailPage extends StatefulWidget {
  const PatrolRecordDetailPage({super.key, required this.uuid});

  final String uuid;

  @override
  State<PatrolRecordDetailPage> createState() =>
      _PatrolRecordDetailPageState();
}

class _PatrolRecordDetailPageState extends State<PatrolRecordDetailPage> {
  late final Future<
      (PatrolRecordHeader? header, List<PatrolRecordBody> body)> _future =
      _load();

  Future<(PatrolRecordHeader?, List<PatrolRecordBody>)> _load() async {
    final header = await PatrolRecordDatabase.instance.getHeaderByUuid(
      widget.uuid,
    );
    final body = await PatrolRecordDatabase.instance.getBodyByUuid(
      widget.uuid,
    );
    return (header, body);
  }

  Widget _cell(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Patrol (Unsync Data)'.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<(PatrolRecordHeader?, List<PatrolRecordBody>)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final header = snapshot.data?.$1;
            final rows = snapshot.data?.$2 ?? [];
            if (rows.isEmpty) {
              return const EmptyItemWidget(
                icon: Icons.qr_code_scanner,
                title: 'No checkpoint scans',
                content: 'This patrol session has no recorded scans.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header?.syncStatus == 'fail' ||
                      header?.syncStatus == 'partial') ...[
                    _SyncFailedBanner(
                      title: header?.syncStatus == 'partial'
                          ? 'Photo upload incomplete'
                          : 'Sync failed',
                      message: header?.message,
                    ),
                    12.ph,
                  ],
                  // Full-width table with fixed column ratios, so its edges
                  // line up with the screen regardless of scancode length
                  // (long values wrap instead of widening the table).
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                    },
                    defaultVerticalAlignment:
                        TableCellVerticalAlignment.middle,
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: AppColor.lightGrey),
                      bottom: BorderSide(color: AppColor.lightGrey),
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.1),
                        ),
                        children: [
                          _cell('Scan Date'.smallTextWithBold()),
                          _cell('Checkpoint'.smallTextWithBold()),
                        ],
                      ),
                      for (final row in rows)
                        TableRow(
                          children: [
                            _cell(row.scanDate.smallText()),
                            _cell(row.scanCode.smallText(maxLine: 3)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SyncFailedBanner extends StatelessWidget {
  const _SyncFailedBanner({required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColor.dangerRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Constants.borderRadiusSmall),
        border: Border.all(color: AppColor.dangerRed),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.w,
        children: [
          Icon(Icons.error_outline, color: AppColor.dangerRed, size: 18.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title.smallTextWithBold(color: AppColor.dangerRed),
                if (message != null && message!.isNotEmpty) ...[
                  4.ph,
                  message!.smallText(color: AppColor.dangerRed),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
