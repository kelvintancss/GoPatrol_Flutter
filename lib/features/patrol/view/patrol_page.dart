import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/services/user_preference.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/patrol/view/patrol_digital_form_page.dart';
import 'package:patrol/features/patrol/widgets/checkpoint_card.dart';
import 'package:patrol/features/patrol/widgets/patrol_shift_dialog.dart';
import 'package:patrol/features/patrol/widgets/patrol_shift_route_dialog.dart';
import 'package:patrol/service_locator.dart';

class PatrolPage extends StatefulWidget {
  const PatrolPage({super.key});

  @override
  State<PatrolPage> createState() => _PatrolPageState();
}

class _PatrolPageState extends State<PatrolPage> {
  late List<PatrolCheckpointEntry> _entries =
      PatrolCheckpointStorage.instance.entries;
  bool _isCoolingDown = false;

  /// Shift confirmed for this patrol (from SQLite); null if none was saved.
  PatrolActiveShift? _activeShift;
  List<PatrolShiftRouteItem> _routes = const [];

  /// Index into [_routes] of the next checkpoint to scan.
  int get _nextIndex =>
      nextRouteIndex(_routes, _entries.reversed.map((e) => e.checkpointId));

  PatrolShiftRouteItem? get _nextCheckpoint =>
      _nextIndex < _routes.length ? _routes[_nextIndex] : null;

  @override
  void initState() {
    super.initState();
    sl<PatrolHomeDataManager>().start();
    // Resumed into an already-started patrol (e.g. app relaunch) — skip the
    // shift picker and keep scanning.
    if (sl<UserPreferences>().isPatrolActive()) {
      _loadActiveShift();
      _startNfcListening();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _selectShift());
    }
  }

  /// Patrol isn't started until a shift is picked; backing out of the
  /// picker returns to home without starting it.
  Future<void> _selectShift() async {
    final shift = await PatrolShiftDialog.show(context);
    if (!mounted) return;
    if (shift == null) {
      context.go(AppRouter.home);
      return;
    }
    final prefs = sl<UserPreferences>();
    await prefs.setPatrolStartTime(DateTime.now());
    await prefs.setPatrolActive(true);
    await _loadActiveShift();
    _startNfcListening();
  }

  Future<void> _loadActiveShift() async {
    final shift = await PatrolShiftDatabase.instance.get();
    if (!mounted) return;
    setState(() {
      _activeShift = shift;
      _routes = shift?.route?.routes ?? const [];
    });
  }

  /// Resolves a scan against the route: the index of the matching
  /// checkpoint at or after [_nextIndex] (anything in between counts as
  /// skipped), or a rejection message. Both null when there's no route
  /// (legacy patrol — any tag is accepted).
  ({int? index, String? rejection}) _resolveScan(String scanId) {
    if (_routes.isEmpty) return (index: null, rejection: null);
    final next = _nextIndex;
    if (next >= _routes.length) {
      return (index: null, rejection: 'All checkpoints completed.');
    }
    for (var i = next; i < _routes.length; i++) {
      if (isSameScanCode(scanId, _routes[i].scanCode)) {
        return (index: i, rejection: null);
      }
    }
    final inRoute = _routes.any((r) => isSameScanCode(scanId, r.scanCode));
    return (
      index: null,
      rejection: inRoute
          ? 'Checkpoint ($scanId) was already scanned or skipped.'
          : 'Checkpoint ($scanId) is not in this shift route.',
    );
  }

  void _showRouteDialog() {
    final shift = _activeShift;
    if (shift == null) return;
    PatrolShiftRouteDialog.show(
      context,
      shift: shift,
      route: shift.route,
      nextIndex: _nextIndex,
    );
  }

  @override
  void dispose() {
    NfcHelper.stop();
    super.dispose();
  }

  Future<void> _startNfcListening() async {
    try {
      await NfcHelper.startContinuousScan(onTagDetected: _onTagDetected);
    } catch (e) {
      if (mounted) CustomDialog.showAppToast('NFC scan failed: $e');
    }
  }

  Future<void> _onTagDetected(String scanId) async {
    // Also stays set while the digital form is open, so further taps are
    // ignored until it's submitted or dismissed.
    if (_isCoolingDown) return;
    _isCoolingDown = true;
    try {
      final (:index, :rejection) = _resolveScan(scanId);
      if (rejection != null) {
        CustomDialog.showAppToast(rejection);
        return;
      }

      // Everything between the next expected checkpoint and the scanned one
      // is skipped; all of them get the moment of this scan as checkdate.
      final skipped = index == null
          ? const <PatrolShiftRouteItem>[]
          : _routes.sublist(_nextIndex, index);
      final skipTime = DateTime.now();
      final newEntries = <PatrolCheckpointEntry>[];
      var saved = false;
      try {
        for (final route in skipped) {
          final entry = await _recordSkip(route, skipTime);
          if (!mounted) return;
          if (entry == null) {
            CustomDialog.showAppToast(
              'Skip form not submitted. Checkpoint not recorded.',
            );
            return;
          }
          newEntries.add(entry);
        }

        final checkpoint = index == null ? null : _routes[index];
        final form = checkpoint?.digitalForm;
        PatrolFormResult? result;
        if (checkpoint != null && form != null) {
          result = await context.push<PatrolFormResult>(
            AppRouter.patrolDigitalForm,
            extra: {'checkpoint': checkpoint, 'form': form},
          );
          if (!mounted) return;
          if (result == null) {
            CustomDialog.showAppToast(
              'Form not submitted. Checkpoint not recorded.',
            );
            return;
          }
        }

        newEntries.add(
          PatrolCheckpointEntry(
            // No route (legacy patrol) — fall back to the raw scan id.
            checkpointId: checkpoint?.checkpointId ?? scanId,
            scanCode: scanId,
            formId: form?.formId ?? '',
            orgFormId: form?.id ?? '',
            formName: form?.formName ?? '',
            formAnswer: result == null ? '' : jsonEncode(result.answers),
            formPhotos: result == null
                ? ''
                : encodePatrolFormPhotos(result.photos),
          ),
        );
        for (final entry in newEntries) {
          await PatrolCheckpointStorage.instance.add(entry);
        }
        saved = true;
      } finally {
        if (!saved) {
          // Aborted part-way — drop photos taken in skip forms already
          // filled for this scan.
          unawaited(
            PatrolFormPhotoStore.deleteFiles(
              newEntries.expand((e) => e.photos).map((p) => p.path),
            ),
          );
        }
      }
      _refreshEntries();
      CustomDialog.showAppToast(
        skipped.isEmpty
            ? 'Checkpoint recorded: $scanId'
            : 'Checkpoint recorded: $scanId '
                  '(skipped: ${skipped.map((r) => r.scanCode).join(', ')})',
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isCoolingDown = false;
    }
  }

  /// Builds the entry for a skipped [route] checkpoint. With a
  /// `digitalFormCheckpointSkip` form, the user is told about the skip and
  /// must fill that form — null if they cancel. Without one, the skip is
  /// recorded silently.
  Future<PatrolCheckpointEntry?> _recordSkip(
    PatrolShiftRouteItem route,
    DateTime skipTime,
  ) async {
    final skipForm = _activeShift?.skipForm;
    if (skipForm == null) {
      return PatrolCheckpointEntry(
        checkpointId: route.checkpointId,
        scanCode: route.scanCode,
        timestamp: skipTime,
        isSkip: true,
      );
    }

    var fillForm = false;
    await CustomDialog.showDialogWithOption(
      context,
      title: 'Checkpoint Skipped',
      desc:
          'Checkpoint (${route.scanCode}) was skipped. '
          'Please fill in the ${skipForm.formName} form.',
      confirmText: 'Fill Form',
      cancelText: 'Cancel',
      confirmCallback: () async {
        fillForm = true;
        return true;
      },
    );
    if (!fillForm || !mounted) return null;

    final result = await context.push<PatrolFormResult>(
      AppRouter.patrolDigitalForm,
      extra: {'checkpoint': route, 'form': skipForm},
    );
    if (result == null) return null;
    return PatrolCheckpointEntry(
      checkpointId: route.checkpointId,
      scanCode: route.scanCode,
      timestamp: skipTime,
      isSkip: true,
      formId: skipForm.formId,
      orgFormId: skipForm.id,
      formName: skipForm.formName,
      formAnswer: jsonEncode(result.answers),
      formPhotos: encodePatrolFormPhotos(result.photos),
    );
  }

  /// Re-opens a recorded checkpoint's digital form (the skip form for a
  /// skipped one) pre-filled with its submitted answers; saving overwrites
  /// the stored answers.
  Future<void> _openEntryForm(PatrolCheckpointEntry entry) async {
    final checkpoint = _routes.firstWhereOrNull(
      (r) => r.checkpointId == entry.checkpointId,
    );
    final form = entry.isSkip
        ? _activeShift?.skipForm
        : checkpoint?.digitalForm;
    if (checkpoint == null || form == null) {
      CustomDialog.showAppToast('Form not found for this checkpoint.');
      return;
    }
    final result = await context.push<PatrolFormResult>(
      AppRouter.patrolDigitalForm,
      extra: {
        'checkpoint': checkpoint,
        'form': form,
        'initialAnswers': entry.decodedFormAnswer,
        'initialPhotos': entry.photos,
      },
    );
    if (result == null) return;
    await PatrolCheckpointStorage.instance.updateForm(
      entry,
      formAnswer: jsonEncode(result.answers),
      formPhotos: encodePatrolFormPhotos(result.photos),
    );
    _refreshEntries();
    CustomDialog.showAppToast('Form updated.');
  }

  void _refreshEntries() {
    if (!mounted) return;
    setState(() => _entries = PatrolCheckpointStorage.instance.entries);
  }

  void _showMenu() {
    CustomDialog.showSelectBtmSheet(
      context,
      filter: const [
        ('incident', 'Incident'),
        ('visitorLog', 'Visitor Log'),
        ('facilityLog', 'Facility Log'),
        ('patrolLog', 'Patrol Log'),
      ],
      onTap: (value, label) {
        if (value == 'incident') {
          context.push(AppRouter.incident);
        } else if (value == 'facilityLog') {
          context.push(AppRouter.facilityLog);
        } else if (value == 'patrolLog') {
          context.push(AppRouter.patrolLog);
        }
      },
    );
  }

  Future<void> _onStopPatrolTap() async {
    var stopped = false;
    await CustomDialog.showDialogWithOption(
      context,
      title: 'Stop Patrol',
      desc:
          'This will clear all checkpoint records for this patrol. '
          'Continue?',
      confirmText: 'Stop',
      cancelText: 'Cancel',
      confirmCallback: () async {
        final entries = PatrolCheckpointStorage.instance.entries;
        if (entries.isNotEmpty) {
          final prefs = sl<UserPreferences>();
          final shift = await PatrolShiftDatabase.instance.get();
          final uuid = await PatrolRecordDatabase.instance.savePatrolRecord(
            startDate: prefs.getPatrolStartTime() ?? DateTime.now(),
            endDate: DateTime.now(),
            calendarId: shift?.calendarId ?? '',
            shiftId: shift?.shiftId ?? '',
            patrolRouteId: shift?.patrolRouteId ?? '',
            entries: entries,
          );
          unawaited(sl<PatrolSyncManager>().trySyncNow(uuid));
        }
        await PatrolCheckpointStorage.instance.clear();
        await PatrolShiftDatabase.instance.clear();
        await sl<UserPreferences>().setPatrolActive(false);
        stopped = true;
        return true;
      },
    );
    if (!stopped || !mounted) return;
    context.go(AppRouter.home);
  }

  Widget _buildShiftLabel(PatrolActiveShift shift) {
    final next = _nextCheckpoint;
    final String nextText;
    if (_routes.isEmpty) {
      nextText = '-';
    } else if (next == null) {
      nextText = 'All completed';
    } else {
      nextText = next.checkpointRemark.isNotEmpty
          ? '${next.scanCode} (${next.checkpointRemark})'
          : next.scanCode;
    }
    return GestureDetector(
      onTap: _showRouteDialog,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    '${shift.shiftName}: (${shift.timeStart} ~ ${shift.timeEnd})'
                        .bodyWithBoldText(maxLine: 1),
                    4.ph,
                    'Next : $nextText'.smallText(
                      color: AppColor.primary,
                      maxLine: 1,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColor.darkGrey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: context.loc.checkPoint.titleBoldText(color: Colors.black),
          isMainPage: false,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: _showMenu,
          ),
        ),
        body: SafeArea(
          child: _entries.isEmpty
              ? const EmptyItemWidget(
                  icon: Icons.nfc,
                  title: 'No checkpoints yet',
                  content:
                      'Tap an NFC tag on the phone to record a '
                      'checkpoint.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(15.0),
                  itemCount: _entries.length,
                  separatorBuilder: (context, index) => 12.ph,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return CheckpointCard(
                      entry: entry,
                      onTap: entry.hasForm ? () => _openEntryForm(entry) : null,
                    );
                  },
                ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_activeShift != null) ...[
                  _buildShiftLabel(_activeShift!),
                  10.ph,
                ],
                CustomAppButton(
                  title: 'Stop Patrol',
                  bgColor: AppColor.dangerRed,
                  onTap: _onStopPatrolTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
