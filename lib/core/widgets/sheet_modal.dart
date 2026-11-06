import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

showBtmSheet(
  BuildContext context, {
  required Widget child,
  bool useRoot = true,
  bool showDragHandle = true,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) async {
  return await showModalBottomSheet(
    context: context,
    useRootNavigator: useRoot,
    showDragHandle: showDragHandle,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    builder: (context) {
      return SafeArea(child: child);
    },
  );
}

class MenuSheet extends StatelessWidget {
  const MenuSheet({
    super.key,
    this.child,
    this.size,
    this.isFixSnap = false,
    this.topBar,
    this.btmBar,
  });
  final Widget? child;
  final double? size;
  final bool isFixSnap;
  final Widget? btmBar;
  final Widget? topBar;
  @override
  Widget build(BuildContext context) {
    var halfWayOffset = SheetOffset(size ?? 0.7);
    if (isFixSnap) {
      return SheetKeyboardDismissible(
        dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(
          isContentScrollAware: true,
        ),
        child: Sheet(
          scrollConfiguration: const SheetScrollConfiguration(),
          decoration: MaterialSheetDecoration(
            size: SheetSize.stretch,
            color: Theme.of(context).colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          child: SheetContentScaffold(
            bottomBarVisibility: const BottomBarVisibility.always(
              ignoreBottomInset: true,
            ),
            body: child == null ? const SizedBox.shrink() : child!,
            bottomBar: btmBar,
            topBar: topBar,
          ),
        ),
      );
    }
    return DefaultSheetController(
      child: Sheet(
        scrollConfiguration: const SheetScrollConfiguration(),
        initialOffset: halfWayOffset,
        snapGrid: SheetSnapGrid(
          snaps: [halfWayOffset, if (!isFixSnap) const SheetOffset(1)],
        ),
        decoration: SheetDecorationBuilder(
          size: SheetSize.stretch,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: CupertinoColors.systemGroupedBackground,
                child: child,
              ),
            );
          },
        ),
        child: Column(
          children: [
            const Divider(height: 1, color: CupertinoColors.systemGrey5),
            Expanded(child: child == null ? const SizedBox.shrink() : child!),
          ],
        ),
      ),
    );
  }
}
