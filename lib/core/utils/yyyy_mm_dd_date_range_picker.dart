import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// [showDateRangePicker] wrapper whose manual-entry Start/End Date text
/// fields (shown when switching the dialog to keyboard input) format and
/// parse as yyyy-MM-dd instead of the locale's default mm/dd/yyyy.
Future<DateTimeRange?> showYyyyMmDdDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
}) {
  return showDateRangePicker(
    context: context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
    builder: (context, child) {
      return Localizations.override(
        context: context,
        delegates: const [_YyyyMmDdMaterialLocalizationsDelegate()],
        child: child,
      );
    },
  );
}

/// English defaults with the compact date field reformatted to yyyy-MM-dd
/// instead of the default mm/dd/yyyy.
class _YyyyMmDdMaterialLocalizations extends DefaultMaterialLocalizations {
  const _YyyyMmDdMaterialLocalizations();

  static final _format = DateFormat('yyyy-MM-dd');

  @override
  String get dateHelpText => 'yyyy-mm-dd';

  @override
  String formatCompactDate(DateTime date) => _format.format(date);

  @override
  DateTime? parseCompactDate(String? inputString) {
    if (inputString == null || inputString.isEmpty) return null;
    try {
      return _format.parseStrict(inputString);
    } catch (_) {
      return null;
    }
  }
}

class _YyyyMmDdMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _YyyyMmDdMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const _YyyyMmDdMaterialLocalizations());

  @override
  bool shouldReload(_YyyyMmDdMaterialLocalizationsDelegate old) => false;
}
