import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/gen/assets.gen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Read-only view of a single visitor log entry from the server report
/// (`/patrol/getpatrolhomedata` snapshot or `/patrol/getvisitorreport`).
class VisitorLogDetailPage extends StatelessWidget {
  const VisitorLogDetailPage({super.key, required this.entry});

  final VisitorLogEntry entry;

  Future<void> _callNumber(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      CustomDialog.showAppToast('Unable to open dialer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactNo = entry.visitorContactNo;
    final hasContactNo = contactNo?.isNotEmpty ?? false;
    final hasQrCode = entry.preGenCodeNo?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Visitor Detail'.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.overstay) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColor.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      Constants.borderRadiusLarge,
                    ),
                    border: Border.all(color: AppColor.dangerRed),
                  ),
                  child: Row(
                    spacing: 8.w,
                    children: [
                      IconWidget(
                        imgPath: Assets.images.warningColorRed.path,
                        height: 20,
                        width: 20,
                      ),
                      'Overstayed'.mediumTextWithBold(color: AppColor.dangerRed),
                    ],
                  ),
                ),
                15.ph,
              ],
              _InfoTile(label: 'Visitor Type', value: entry.vmsType),
              _InfoTile(label: 'Lot No', value: entry.lotNo),
              _InfoTile(label: 'Visitor Name', value: entry.visitorName),
              _InfoTile(
                label: 'Contact No',
                value: hasContactNo ? contactNo! : '-',
                trailing: hasContactNo
                    ? IconWidget(
                        imgPath: Assets.images.callColorMainBlue.path,
                        height: 24,
                        width: 24,
                      )
                    : null,
                onTap: hasContactNo
                    ? () => _callNumber(context, contactNo!)
                    : null,
              ),
              _InfoTile(
                label: 'Vehicle No',
                value: entry.visitorVehicleNo ?? '-',
              ),
              _InfoTile(
                label: 'Check In Date',
                value: entry.checkInDate ?? '-',
              ),
              _InfoTile(
                label: 'Visit Date To',
                value: entry.visitDateTo ?? '-',
              ),
              if (hasQrCode) ...[
                10.ph,
                'Pre-Gen Code'.bodyWithBoldText(),
                10.ph,
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(
                        Constants.borderRadiusLarge,
                      ),
                      border: Border.all(color: AppColor.lightGrey),
                    ),
                    child: QrImageView(
                      data: entry.preGenCodeNo!,
                      size: 180.w,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
          border: Border.all(color: AppColor.lightGrey),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4.h,
                children: [
                  label.smallText(color: AppColor.textGrey),
                  value.mediumTextWithBold(),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
