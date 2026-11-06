import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/patrol/widgets/patrol_record_card.dart';
import 'package:patrol/service_locator.dart';

class PatrolRecordListPage extends StatefulWidget {
  const PatrolRecordListPage({super.key});

  @override
  State<PatrolRecordListPage> createState() => _PatrolRecordListPageState();
}

class _PatrolRecordListPageState extends State<PatrolRecordListPage> {
  late Future<List<PatrolRecordHeader>> _future = _loadHeaders();
  bool _isSyncing = false;

  Future<List<PatrolRecordHeader>> _loadHeaders() =>
      PatrolRecordDatabase.instance.getHeaders();

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _loadHeaders();
    });
  }

  Future<void> _onSyncTap() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    var hasInternet = false;
    try {
      hasInternet = await sl<PatrolSyncManager>().syncNow();
    } finally {
      // Always resolves to a message and resets the button, even if
      // syncNow() throws — otherwise the button would stay stuck on
      // "Syncing..." with no feedback to the user at all.
      if (mounted) {
        setState(() => _isSyncing = false);
        _refresh();
      }
      CustomDialog.showAppToast(
        hasInternet
            ? 'Sync completed.'
            : 'No internet connection, please try again.',
      );
      debugPrint('[SYNC_DEBUG] _onSyncTap: toast call returned');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Patrol (Unsync Data)'.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<PatrolRecordHeader>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final records = snapshot.data ?? [];
            if (records.isEmpty) {
              return const EmptyItemWidget(
                icon: Icons.history,
                title: 'No patrol records yet',
                content: 'Completed patrol sessions will appear here.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(15.0),
              itemCount: records.length,
              separatorBuilder: (context, index) => 12.ph,
              itemBuilder: (context, index) {
                final record = records[index];
                return PatrolRecordCard(
                  record: record,
                  onTap: () => context.push(
                    AppRouter.patrolRecordDetail,
                    extra: {'uuid': record.uuid},
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<List<PatrolRecordHeader>>(
        future: _future,
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          final hasUnsynced = records.any(
            (r) => const {'pending', 'fail', 'partial'}.contains(r.syncStatus),
          );
          if (!hasUnsynced) return const SizedBox.shrink();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
              child: SizedBox(
                width: double.infinity,
                child: CustomAppButton(
                  title: _isSyncing ? 'Syncing...' : 'Sync Record',
                  bgColor: AppColor.primary,
                  onTap: _isSyncing ? null : _onSyncTap,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
