import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/incident/widgets/incident_card.dart';
import 'package:patrol/service_locator.dart';

class IncidentRecordListPage extends StatefulWidget {
  const IncidentRecordListPage({super.key});

  @override
  State<IncidentRecordListPage> createState() =>
      _IncidentRecordListPageState();
}

class _IncidentRecordListPageState extends State<IncidentRecordListPage> {
  late Future<List<IncidentRecord>> _future = _loadRecords();
  bool _isSyncing = false;

  Future<List<IncidentRecord>> _loadRecords() =>
      IncidentRecordDatabase.instance.getIncidents();

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _loadRecords();
    });
  }

  Future<void> _onSyncTap() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    var hasInternet = false;
    try {
      hasInternet = await sl<IncidentSyncManager>().syncNow();
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
    }
  }

  void _onIncidentCardTap(IncidentRecord record) {
    context.push(AppRouter.addIncident, extra: {'uuid': record.uuid});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Incident (Unsync Data)'.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<IncidentRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final records = snapshot.data ?? [];
            if (records.isEmpty) {
              return const Center(
                child: EmptyItemWidget(
                  icon: Icons.report_gmailerrorred,
                  title: 'No incidents yet',
                  content: 'Reported incidents will appear here.',
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(15.0),
              itemCount: records.length,
              separatorBuilder: (context, index) => 12.ph,
              itemBuilder: (context, index) {
                final record = records[index];
                return IncidentCard(
                  record: record,
                  onTap: () => _onIncidentCardTap(record),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<List<IncidentRecord>>(
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
                  title: _isSyncing ? 'Syncing...' : 'Sync Incident',
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
