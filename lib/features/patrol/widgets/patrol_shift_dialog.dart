import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/repository/patrol_repository.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/patrol/widgets/patrol_route_card.dart';
import 'package:patrol/service_locator.dart';

/// Modal that fetches `/patrol/getPatrolCalendarShift` and lists the shifts.
/// Tapping a card selects it; Confirm fetches that shift's route, stores
/// both in [PatrolShiftDatabase], then pops with the selected
/// [PatrolCalendarShift]. "Back to Home" pops with `null` (patrol not
/// started). A card's more icon swaps the content to that shift's route
/// (`/patrol/getPatrolShiftRoute`).
class PatrolShiftDialog extends StatefulWidget {
  const PatrolShiftDialog({super.key});

  static Future<PatrolCalendarShift?> show(BuildContext context) {
    return showDialog<PatrolCalendarShift>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PatrolShiftDialog(),
    );
  }

  @override
  State<PatrolShiftDialog> createState() => _PatrolShiftDialogState();
}

class _PatrolShiftDialogState extends State<PatrolShiftDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PatrolCalendarShift> _shifts = const [];
  PatrolCalendarShift? _selectedShift;
  bool _isConfirming = false;

  /// Non-null while the route view is shown.
  PatrolCalendarShift? _routeShift;
  bool _isRouteLoading = false;
  String? _routeErrorMessage;
  PatrolShiftRoute? _route;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await sl<PatrolRepository>().getPatrolCalendarShift();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _shifts = result.shifts;
        _errorMessage = result.success
            ? null
            : (result.message?.isNotEmpty == true
                ? result.message
                : context.loc.generalErrorMsg);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = context.loc.generalErrorMsg;
      });
    }
  }

  Future<void> _fetchRoute(PatrolCalendarShift shift) async {
    setState(() {
      _routeShift = shift;
      _isRouteLoading = true;
      _routeErrorMessage = null;
      _route = null;
    });
    try {
      final result = await sl<PatrolRepository>()
          .getPatrolShiftRoute(shiftId: shift.shiftId);
      // Ignore a late response if the user already left this route view.
      if (!mounted || _routeShift != shift) return;
      setState(() {
        _isRouteLoading = false;
        _route = result.route;
        _routeErrorMessage = result.success
            ? null
            : (result.message?.isNotEmpty == true
                ? result.message
                : context.loc.generalErrorMsg);
      });
    } catch (_) {
      if (!mounted || _routeShift != shift) return;
      setState(() {
        _isRouteLoading = false;
        _routeErrorMessage = context.loc.generalErrorMsg;
      });
    }
  }

  void _closeRoute() => setState(() => _routeShift = null);

  Future<void> _onConfirm() async {
    final shift = _selectedShift;
    if (_isConfirming) return;
    if (shift == null) {
      CustomDialog.showAppToast('Please select a shift.');
      return;
    }
    setState(() => _isConfirming = true);
    try {
      final result = await sl<PatrolRepository>()
          .getPatrolShiftRoute(shiftId: shift.shiftId);
      if (!mounted) return;
      if (!result.success) {
        CustomDialog.showAppToast(result.message?.isNotEmpty == true
            ? result.message!
            : context.loc.generalErrorMsg);
        return;
      }
      await PatrolShiftDatabase.instance.save(
        shift: shift,
        patrolRouteId: result.route?.patrolRouteId ?? '',
        routeJson: result.routeJson,
        skipFormJson: result.skipFormJson,
      );
      if (mounted) Navigator.of(context).pop(shift);
    } catch (_) {
      if (mounted) CustomDialog.showAppToast(context.loc.generalErrorMsg);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          message.bodyText(
            textAlign: TextAlign.center,
            maxLine: 3,
            color: AppColor.dangerRed,
          ),
          10.ph,
          TextButton(onPressed: onRetry, child: 'Retry'.bodyText()),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: message.bodyText(
        textAlign: TextAlign.center,
        color: AppColor.textGrey,
      ),
    );
  }

  Widget _buildShiftList() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError(_errorMessage!, _fetchShifts);
    if (_shifts.isEmpty) return _buildEmpty('No patrol shift available.');
    return Flexible(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _shifts.length,
        separatorBuilder: (context, index) => 8.ph,
        itemBuilder: (context, index) {
          final shift = _shifts[index];
          return _ShiftCard(
            shift: shift,
            isSelected: identical(shift, _selectedShift),
            onTap: () => setState(() => _selectedShift = shift),
            onMoreTap: () => _fetchRoute(shift),
          );
        },
      ),
    );
  }

  Widget _buildRouteView() {
    final shift = _routeShift!;
    Widget content;
    if (_isRouteLoading) {
      content = _buildLoading();
    } else if (_routeErrorMessage != null) {
      content = _buildError(_routeErrorMessage!, () => _fetchRoute(shift));
    } else if (_route == null || _route!.routes.isEmpty) {
      content = _buildEmpty('No route available for this shift.');
    } else {
      content = Flexible(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _route!.routes.length,
          separatorBuilder: (context, index) => 8.ph,
          itemBuilder: (context, index) =>
              PatrolRouteCard(item: _route!.routes[index]),
        ),
      );
    }

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          shift.shiftName.bodyWithBoldText(maxLine: 1),
          if (_route != null && _route!.version.isNotEmpty) ...[
            4.ph,
            'Version: ${_route!.version}'.smallText(color: AppColor.textGrey),
          ],
          10.ph,
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRouteView = _routeShift != null;
    return PopScope(
      canPop: false,
      // System back closes the route view first, otherwise behaves like the
      // "Back to Home" button.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isConfirming) return;
        if (isRouteView) {
          _closeRoute();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 0.75.sh),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (isRouteView)
                      GestureDetector(
                        onTap: _closeRoute,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.arrow_back, color: Colors.black),
                        ),
                      ),
                    Expanded(
                      child: (isRouteView ? 'Shift Route' : 'Patrol Shift')
                          .titleBoldText(color: Colors.black),
                    ),
                  ],
                ),
                12.ph,
                isRouteView ? _buildRouteView() : _buildShiftList(),
                15.ph,
                if (isRouteView)
                  CustomAppButton(
                    title: 'Back',
                    bgColor: AppColor.darkGrey,
                    onTap: _closeRoute,
                  )
                else ...[
                  CustomAppButton(
                    title: _isConfirming ? 'Loading...' : 'Confirm',
                    bgColor: _selectedShift == null || _isConfirming
                        ? AppColor.disabledBackgroundColor
                        : AppColor.primary,
                    onTap: _onConfirm,
                  ),
                  10.ph,
                  CustomAppButton(
                    title: 'Back to Home',
                    bgColor: AppColor.darkGrey,
                    onTap: _isConfirming
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.shift,
    required this.isSelected,
    required this.onTap,
    required this.onMoreTap,
  });

  final PatrolCalendarShift shift;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
          side: BorderSide(
            color: isSelected ? AppColor.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 15, 5, 15),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColor.primary.withValues(alpha: 0.08)
                : AppColor.white,
            borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
          ),
          child: Row(
            spacing: 10.w,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColor.primary : AppColor.darkGrey,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shift.shiftName.bodyWithBoldText(fontSize: 15, maxLine: 1),
                    6.ph,
                    shift.day.smallText(color: AppColor.textGrey),
                    4.ph,
                    '${shift.timeStart}  ~  ${shift.timeEnd}'
                        .smallText(color: AppColor.textGrey),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColor.primary),
                onPressed: onMoreTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
