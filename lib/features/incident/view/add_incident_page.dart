import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/incident/widgets/read_only_digital_form.dart';
import 'package:patrol/features/patrol/view/patrol_digital_form_page.dart';
import 'package:patrol/service_locator.dart';

class AddIncidentPage extends StatefulWidget {
  const AddIncidentPage({super.key, this.uuid});

  /// Non-null when opened to view a locally-saved incident — it's looked up
  /// from the database by this uuid and shown read-only.
  final String? uuid;

  bool get isViewMode => uuid != null;

  @override
  State<AddIncidentPage> createState() => _AddIncidentPageState();
}

class _AddIncidentPageState extends State<AddIncidentPage> {
  IncidentRecord? _record;

  /// Old (pre digital form) incidents' photo rows.
  List<String> _legacyPhotoPaths = [];
  PatrolDigitalForm? _form;
  late final Future<void> _loadFuture =
      widget.isViewMode ? _loadExistingData() : _loadIncidentForm();

  Future<void> _loadExistingData() async {
    final uuid = widget.uuid;
    if (uuid == null) return;
    try {
      final record = await IncidentRecordDatabase.instance.getIncidentByUuid(
        uuid,
      );
      _record = record;
      if (record != null && record.isLegacy) {
        final photos = await IncidentRecordDatabase.instance
            .getPhotosByIncidentUuid(uuid);
        _legacyPhotoPaths = photos.map((p) => p.photoPath).toList();
      }
    } catch (_) {
      // Page may already be gone — nothing left to update.
    }
  }

  /// The Add Incident form is `incident_digitalform` from the SQLite
  /// home-data snapshot; one foreground fetch if it isn't there yet.
  Future<void> _loadIncidentForm() async {
    var form = (await PatrolHomeDataDatabase.instance.get())?.incidentForm;
    if (form == null) {
      await sl<PatrolHomeDataManager>().fetchNow();
      form = (await PatrolHomeDataDatabase.instance.get())?.incidentForm;
    }
    _form = form;
  }

  /// Saved locally first, then posted right away if online — otherwise the
  /// background sweep in [IncidentSyncManager] retries later.
  Future<void> _onSubmit(PatrolDigitalForm form, PatrolFormResult result) async {
    final uuid = await IncidentRecordDatabase.instance.addIncident(
      orgFormId: form.id,
      formName: form.formName,
      formAnswer: jsonEncode(result.answers),
      photos: result.photos,
    );
    unawaited(sl<IncidentSyncManager>().trySyncNow(uuid));
    if (!mounted) return;
    CustomDialog.showAppToast('Incident submitted.');
    context.pop(true);
  }

  List<PatrolFormItem> _decodeAnswers(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => PatrolFormItem(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _openImageViewer(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewerPage(imagePath: path),
      ),
    );
  }

  Widget _buildPhotoSection(List<String> paths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        'Attach Image'.bodyWithBoldText(),
        10.ph,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final path in paths)
              GestureDetector(
                onTap: () => _openImageViewer(path),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(Constants.borderRadiusSmall),
                  child: Image.file(
                    File(path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColor.textGrey,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewBody() {
    final record = _record;
    if (record == null) {
      return const EmptyItemWidget(
        icon: Icons.report_gmailerrorred,
        title: 'Incident not found',
        content: 'This incident is no longer saved on this device.',
      );
    }
    if (record.isLegacy) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_legacyPhotoPaths.isNotEmpty) ...[
              _buildPhotoSection(_legacyPhotoPaths),
              15.ph,
            ],
            'Description'.bodyWithBoldText(),
            10.ph,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius:
                    BorderRadius.circular(Constants.borderRadiusLarge),
                border: Border.all(color: AppColor.lightGrey),
              ),
              child: record.remark.bodyText(maxLine: 9999),
            ),
          ],
        ),
      );
    }

    final photos = record.photos;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadOnlyDigitalForm(items: _decodeAnswers(record.formAnswer)),
          if (photos.isNotEmpty) ...[
            10.ph,
            _buildPhotoSection(photos.map((p) => p.path).toList()),
          ] else if (record.formAttachment > 0) ...[
            10.ph,
            '${record.formAttachment} photo(s) uploaded.'
                .smallText(color: AppColor.textGrey),
          ],
        ],
      ),
    );
  }

  Widget _buildScaffold(String title, Widget body) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: title.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(child: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildScaffold(
            widget.isViewMode ? 'Incident Detail' : 'Add Incident',
            const Center(child: CircularProgressIndicator()),
          );
        }
        if (widget.isViewMode) {
          final formName = _record?.formName ?? '';
          return _buildScaffold(
            formName.isNotEmpty ? formName : 'Incident Detail',
            _buildViewBody(),
          );
        }

        final form = _form;
        if (form == null) {
          return _buildScaffold(
            'Add Incident',
            const EmptyItemWidget(
              icon: Icons.report_gmailerrorred,
              title: 'No incident form',
              content: 'The incident form is not available. '
                  'Please check your internet connection and try again.',
            ),
          );
        }
        return PatrolDigitalFormPage(
          form: form,
          onSubmit: (result) => _onSubmit(form, result),
        );
      },
    );
  }
}

class _PhotoViewerPage extends StatelessWidget {
  const _PhotoViewerPage({required this.imagePath});

  final String imagePath;

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
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}
