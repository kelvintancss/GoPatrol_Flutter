import 'package:custom_network_image/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/incident/widgets/read_only_digital_form.dart';

/// Read-only view of a single incident log entry from the server report
/// (`/patrol/getpatrolhomedata` snapshot or `/patrol/getincidentreport`):
/// its submitted `digitalFormDetail` answers plus `attach_image`. Nothing
/// here can be edited — the data belongs to the server.
class IncidentLogDetailPage extends StatelessWidget {
  const IncidentLogDetailPage({super.key, required this.entry});

  final IncidentLogEntry entry;

  void _openImageViewer(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _NetworkPhotoViewerPage(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: (entry.formName.isNotEmpty ? entry.formName : 'Incident Detail')
            .titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(Constants.borderRadiusLarge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    entry.cssLoginCode.bodyWithBoldText(),
                    4.ph,
                    formatPatrolLogDate(entry.dateInput)
                        .smallText(color: AppColor.textGrey),
                  ],
                ),
              ),
              10.ph,
              ReadOnlyDigitalForm(items: entry.formItems),
              if (entry.attachImages.isNotEmpty) ...[
                10.ph,
                'Attach Image'.bodyWithBoldText(),
                10.ph,
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: entry.attachImages
                      .map(
                        (url) => GestureDetector(
                          onTap: () => _openImageViewer(context, url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Constants.borderRadiusSmall,
                            ),
                            child: CustomCachedImageWidget(
                              imgUrl: url,
                              height: 80,
                              width: 80,
                              boxFit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkPhotoViewerPage extends StatelessWidget {
  const _NetworkPhotoViewerPage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: CustomCachedImageWidget(imgUrl: imageUrl, boxFit: BoxFit.contain),
        ),
      ),
    );
  }
}
