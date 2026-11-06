import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/repository/patrol_repository.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/visitor_log/widgets/visitor_log_card.dart';
import 'package:patrol/gen/assets.gen.dart';
import 'package:patrol/service_locator.dart';

class VisitorLogPage extends StatefulWidget {
  const VisitorLogPage({super.key});

  @override
  State<VisitorLogPage> createState() => _VisitorLogPageState();
}

class _VisitorLogPageState extends State<VisitorLogPage> {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static const _checkInType = 'checkinlog';
  static const _checkOutType = 'checkoutlog';

  final TextEditingController _searchController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _logType = _checkInType;
  bool _isLoading = false;
  bool _hasSearched = false;
  List<VisitorLogMonth> _months = [];

  @override
  void initState() {
    super.initState();
    _loadFromLocal(_logType);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Today's snapshot lives in SQLite already (refreshed every 5 minutes by
  /// [PatrolHomeDataManager]), so the initial view — before Search is ever
  /// tapped — normally needs no API call of its own.
  Future<void> _loadFromLocal(String logType) async {
    setState(() => _isLoading = true);
    var report = await _readLocalReport(logType);
    if (report == null || report.log.isEmpty) {
      // Landing here can race the background PatrolHomeDataManager fetch
      // that HomePage just kicked off (or land before it has run at all) —
      // force one foreground attempt so the first-ever open of this page
      // doesn't depend on winning that race.
      await sl<PatrolHomeDataManager>().fetchNow();
      report = await _readLocalReport(logType);
    }
    if (!mounted) return;
    setState(() {
      _months = report?.log ?? [];
      _isLoading = false;
    });
  }

  Future<VisitorLogReport?> _readLocalReport(String logType) async {
    final data = await PatrolHomeDataDatabase.instance.get();
    return parseVisitorLogReport(
      logType == _checkInType ? data?.checkin : data?.checkout,
    );
  }

  /// Before Search has ever been tapped, switching the segment is treated
  /// as a fresh, local-only view of that log type — mirrors the page's
  /// initial state. Once the user has searched at least once, their date
  /// range and keyword are left untouched and re-submitted against the new
  /// log type instead, rather than being silently reset.
  Future<void> _onSegmentTap(String logType) async {
    if (logType == _logType || _isLoading) return;
    setState(() => _logType = logType);

    if (!_hasSearched) {
      setState(() {
        _startDate = DateTime.now();
        _endDate = DateTime.now();
        _searchController.clear();
      });
      await _loadFromLocal(logType);
      return;
    }

    await _runSearch();
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

  Future<void> _onScanTap() async {
    final result = await context.push(
      AppRouter.scanQr,
      extra: {'showGalleryButton': true},
    );
    if (!mounted || result == null) return;
    setState(() => _searchController.text = result.toString());
  }

  Future<void> _onSearchTap() async {
    if (_isLoading) return;
    _hasSearched = true;
    await _runSearch();
  }

  Future<void> _runSearch() async {
    if (!await _hasInternet()) {
      CustomDialog.showAppToast('No internet connection, please try again.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await sl<PatrolRepository>().getVisitorReport(
        startDate: _dateFormat.format(_startDate),
        endDate: _dateFormat.format(_endDate),
        logType: _logType,
        searchText: _searchController.text.trim(),
      );
      if (!mounted) return;
      if (result.success) {
        setState(() => _months = result.report?.log ?? []);
      } else {
        CustomDialog.showAppToast(
          result.message ?? 'Failed to load visitor report.',
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

  void _onEntryTap(VisitorLogEntry entry) {
    context.push(AppRouter.visitorLogDetail, extra: entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Visitor Log'.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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
            10.ph,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                spacing: 10.w,
                children: [
                  Expanded(
                    child: Container(
                      height: 43.h,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColor.lightGrey),
                        borderRadius: BorderRadius.circular(
                          Constants.borderRadiusSmall,
                        ),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _searchController,
                          style: st(fontSize: 14.sp),
                          textAlignVertical: TextAlignVertical.center,
                          inputFormatters: [EmojiFilterFormatter()],
                          decoration: InputDecoration(
                            isDense: true,
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search lot no / visitor name / code',
                            hintStyle: st(
                              fontSize: 14.sp,
                              color: AppColor.hintGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _onScanTap,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconWidget(
                            imgPath: Assets.images.scanColorMainGreen.path,
                            height: 18,
                            width: 18,
                          ),
                          5.pw,
                          'Scan QR'.smallText(color: AppColor.textGrey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            15.ph,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: _VisitorTypeSegment(
                isCheckIn: _logType == _checkInType,
                onChanged: (isCheckIn) =>
                    _onSegmentTap(isCheckIn ? _checkInType : _checkOutType),
              ),
            ),
            10.ph,
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _months.isEmpty
                  ? const EmptyItemWidget(
                      icon: Icons.people_outline,
                      title: 'No visitor records',
                      content:
                          'Visitor records for the selected range will '
                          'appear here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      itemCount: _months.length,
                      itemBuilder: (context, index) => _MonthSection(
                        month: _months[index],
                        onEntryTap: _onEntryTap,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped Check In / Check Out toggle — a single sliding indicator
/// behind two tap targets, rather than two separate buttons side by side.
class _VisitorTypeSegment extends StatelessWidget {
  const _VisitorTypeSegment({required this.isCheckIn, required this.onChanged});

  final bool isCheckIn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColor.lightGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Constants.borderRadiusSmall + 8),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isCheckIn
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(
                    Constants.borderRadiusSmall + 6,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _SegmentLabel(
                  title: 'Check In',
                  isSelected: isCheckIn,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _SegmentLabel(
                  title: 'Check Out',
                  isSelected: !isCheckIn,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: st(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColor.textGrey,
          ),
          child: Text(title),
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.month, required this.onEntryTap});

  final VisitorLogMonth month;
  final ValueChanged<VisitorLogEntry> onEntryTap;

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
                  child: group.createdDate.bodyText(
                    textAlign: TextAlign.center,
                  ),
                ),
                ...group.data.map(
                  (entry) =>
                      VisitorLogCard(entry: entry, onTap: () => onEntryTap(entry)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
