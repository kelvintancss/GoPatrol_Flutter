import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/repository/patrol_repository.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/facility_log/widgets/facility_log_card.dart';
import 'package:patrol/service_locator.dart';

class FacilityLogPage extends StatefulWidget {
  const FacilityLogPage({super.key});

  @override
  State<FacilityLogPage> createState() => _FacilityLogPageState();
}

class _FacilityLogPageState extends State<FacilityLogPage> {
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<FacilityLogMonth> _months = [];

  @override
  void initState() {
    super.initState();
    _loadFromLocal();
  }

  /// Today's snapshot lives in SQLite already (refreshed every 5 minutes by
  /// [PatrolHomeDataManager]), so the initial view normally needs no API
  /// call of its own.
  Future<void> _loadFromLocal() async {
    setState(() => _isLoading = true);
    var report = await _readLocalReport();
    if (report == null || report.log.isEmpty) {
      // Landing here can race the background PatrolHomeDataManager fetch
      // that HomePage/PatrolPage just kicked off (or land before it has run
      // at all) — force one foreground attempt so the first-ever open of
      // this page doesn't depend on winning that race.
      await sl<PatrolHomeDataManager>().fetchNow();
      report = await _readLocalReport();
    }
    if (!mounted) return;
    setState(() {
      _months = report?.log ?? [];
      _isLoading = false;
    });
  }

  Future<FacilityLogReport?> _readLocalReport() async {
    final data = await PatrolHomeDataDatabase.instance.get();
    return parseFacilityLogReport(data?.facility);
  }

  Future<void> _pickDateRange() async {
    final picked = await showYyyyMmDdDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
    });
  }

  Future<void> _onSearchTap() async {
    if (_isLoading) return;

    if (!await _hasInternet()) {
      CustomDialog.showAppToast('No internet connection, please try again.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await sl<PatrolRepository>().getFacilityReport(
        startDate: _dateFormat.format(_startDate),
        endDate: _dateFormat.format(_endDate),
      );
      if (!mounted) return;
      if (result.success) {
        setState(() => _months = result.report?.log ?? []);
      } else {
        CustomDialog.showAppToast(
          result.message ?? 'Failed to load facility report.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _hasInternet() async {
    try {
      // Bounded even if the underlying check ever hangs (e.g. DNS stalls
      // instead of failing fast), so this never stalls the Search tap.
      return await InternetConnection().hasInternetAccess.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Facility Log'.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                spacing: 10.w,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        height: 43.h,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColor.lightGrey),
                          borderRadius: BorderRadius.circular(
                            Constants.borderRadiusSmall,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 18.sp,
                              color: AppColor.textGrey,
                            ),
                            8.pw,
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child:
                                    '${_dateFormat.format(_startDate)} ~ ${_dateFormat.format(_endDate)}'
                                        .bodyText(maxLine: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CustomAppButton(
                    title: 'Search',
                    onTap: _isLoading ? null : _onSearchTap,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _months.isEmpty
                      ? const EmptyItemWidget(
                          icon: Icons.event_busy,
                          title: 'No facility bookings',
                          content:
                              'Facility bookings for the selected range will '
                              'appear here.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          itemCount: _months.length,
                          itemBuilder: (context, index) =>
                              _MonthSection(month: _months[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.month});

  final FacilityLogMonth month;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: month.month.bodyWithBoldText(color: Colors.black),
        ),
        ...month.dateGroups.map(
          (group) => Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10.h,
              children: [
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: '${group.bookingDate} (${group.bookingDay})'
                      .bodyText(textAlign: TextAlign.center),
                ),
                ...group.data.map(
                  (entry) => FacilityLogCard(entry: entry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
