import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/image_helper.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/service_locator.dart';

/// What [PatrolDigitalFormPage] pops with on submit.
class PatrolFormResult {
  /// Answered form items (`itemno != null` rows, each the original JSON with
  /// `formValue` / `formItemGroupList` filled).
  final List<Map<String, dynamic>> answers;

  /// Compressed `.webp` photos from the ATTACHMENT items.
  final List<PatrolFormPhoto> photos;

  const PatrolFormResult({required this.answers, required this.photos});
}

/// Fills a checkpoint's `digitalFormDetail` (UI modelled on CSS Home's
/// `AddFormPage` / `CustomFormWidget`). Pops with a [PatrolFormResult], or
/// `null` if the user backs out. [initialAnswers] / [initialPhotos] (a
/// previous submission) pre-fill the form for editing.
///
/// Also used for the Add Incident form, with no [checkpoint].
class PatrolDigitalFormPage extends StatefulWidget {
  const PatrolDigitalFormPage({
    super.key,
    this.checkpoint,
    required this.form,
    this.initialAnswers,
    this.initialPhotos = const [],
    this.onSubmit,
  });

  /// Shown as a scan code card above the form; null hides it.
  final PatrolShiftRouteItem? checkpoint;
  final PatrolDigitalForm form;
  final List<Map<String, dynamic>>? initialAnswers;
  final List<PatrolFormPhoto> initialPhotos;

  /// When set, a valid submit hands the result here instead of popping
  /// with it (the callback is then in charge of leaving the page).
  final Future<void> Function(PatrolFormResult result)? onSubmit;

  bool get isEdit => initialAnswers != null;

  @override
  State<PatrolDigitalFormPage> createState() => _PatrolDigitalFormPageState();
}

class _PatrolDigitalFormPageState extends State<PatrolDigitalFormPage> {
  static const _groupItem = 'formItemGroupItem';
  static const _groupItemValue = 'formItemGroupItemValue';
  static const _attachment = 'ATTACHMENT';
  static const _maxPhotosPerItem = 5;

  /// Types whose answer lives in [_values] (checked when mandatory).
  static const _valueTypes = {
    'TEXT',
    'EMAIL',
    'SHORT TEXT',
    'LONG TEXT',
    'INTEGER',
    'DECIMAL',
    'DATETIME',
  };

  /// Keyed by index into `form.formItems`.
  final Map<int, String> _values = {};
  final Map<int, List<Map<String, dynamic>>> _groups = {};
  final Map<int, List<PatrolFormPhoto>> _photos = {};

  /// Photos taken in this visit — deleted again if the form isn't
  /// submitted.
  final Set<String> _newPhotoPaths = {};

  /// Previously submitted photos removed in this visit — only deleted once
  /// the form is submitted, so backing out keeps them.
  final Set<String> _removedPhotoPaths = {};
  bool _submitted = false;

  /// Item index currently compressing picked photos.
  int? _processingIndex;

  List<PatrolFormItem> get _items => widget.form.formItems;

  @override
  void initState() {
    super.initState();
    for (final (i, item) in _items.indexed) {
      // Prefer the previously submitted answer for this itemno, if any.
      final saved = item.itemNo == null
          ? null
          : widget.initialAnswers
              ?.firstWhereOrNull((a) => a['itemno'] == item.itemNo);
      final source = saved != null ? PatrolFormItem(saved) : item;
      if (source.formValue != null) _values[i] = source.formValue!;
      if (item.hasGroupList) _groups[i] = source.decodeGroupList();
    }
    _assignInitialPhotos();
  }

  /// Puts each saved photo back under its ATTACHMENT item (by itemno);
  /// unmatched ones go to the first ATTACHMENT item.
  void _assignInitialPhotos() {
    final attachmentIndexes = [
      for (final (i, item) in _items.indexed)
        if (item.typeId == _attachment) i,
    ];
    if (attachmentIndexes.isEmpty) return;
    for (final photo in widget.initialPhotos) {
      final index = attachmentIndexes.firstWhere(
        (i) => _items[i].itemNo == photo.itemNo,
        orElse: () => attachmentIndexes.first,
      );
      _photos.putIfAbsent(index, () => []).add(photo);
    }
  }

  @override
  void dispose() {
    if (!_submitted) {
      unawaited(PatrolFormPhotoStore.deleteFiles(_newPhotoPaths));
    }
    super.dispose();
  }

  void _onSubmit() {
    // Guards a double tap while an [PatrolDigitalFormPage.onSubmit] saves.
    if (_submitted) return;
    if (_processingIndex != null) {
      CustomDialog.showAppToast('Please wait, processing photos...');
      return;
    }
    for (final (i, item) in _items.indexed) {
      if (item.itemNo == null || !item.isMandatory) continue;
      if (item.typeId == _attachment) {
        if ((_photos[i] ?? const []).isEmpty) {
          CustomDialog.showAppToast('${item.labelText} is required.');
          return;
        }
      } else if (item.hasGroupList) {
        final selected =
            _groups[i]?.firstWhereOrNull((e) => e[_groupItemValue] == true);
        if (selected == null) {
          final name = item.groupName.isNotEmpty ? item.groupName : item.labelText;
          CustomDialog.showAppToast('$name is required.');
          return;
        }
      } else if (_valueTypes.contains(item.typeId) &&
          (_values[i] ?? '').trim().isEmpty) {
        CustomDialog.showAppToast('${item.labelText} is required.');
        return;
      }
    }

    final answers = <Map<String, dynamic>>[];
    for (final (i, item) in _items.indexed) {
      if (item.itemNo == null) continue;
      final answer = Map<String, dynamic>.from(item.raw);
      if (_values.containsKey(i)) answer['formValue'] = _values[i];
      if (_groups.containsKey(i)) answer['formItemGroupList'] = _groups[i];
      answers.add(answer);
    }
    _submitted = true;
    unawaited(PatrolFormPhotoStore.deleteFiles(_removedPhotoPaths));
    final result = PatrolFormResult(
      answers: answers,
      photos: [for (final photos in _photos.values) ...photos],
    );
    final onSubmit = widget.onSubmit;
    if (onSubmit != null) {
      unawaited(onSubmit(result));
    } else {
      context.pop(result);
    }
  }

  Future<ImageSource?> _pickImageSource() async {
    final result = await showBtmSheet(
      context,
      isScrollControlled: false,
      child: Builder(
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColor.primary,
                ),
                title: 'Take Photo'.bodyText(),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColor.primary,
                ),
                title: 'Choose from Gallery'.bodyText(),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    return result as ImageSource?;
  }

  Future<void> _onAddPhoto(int i, PatrolFormItem item) async {
    final remaining = _maxPhotosPerItem - (_photos[i]?.length ?? 0);
    if (remaining <= 0) return;
    final source = await _pickImageSource();
    if (source == null || !mounted) return;

    final imageHelper = sl<ImageHelper>();
    List<XFile> picked;
    try {
      if (source == ImageSource.camera) {
        final photo = await imageHelper.takeCamera();
        picked = [?photo];
      } else if (remaining > 1) {
        picked = await imageHelper.pickMultipleImage(max: remaining);
      } else {
        final photo = await imageHelper.pickImage();
        picked = [?photo];
      }
    } catch (_) {
      CustomDialog.showAppToast('Unable to get photo.');
      return;
    }
    if (picked.isEmpty || !mounted) return;
    if (picked.length > remaining) {
      CustomDialog.showAppToast('Maximum $_maxPhotosPerItem photos.');
      picked = picked.take(remaining).toList();
    }

    setState(() => _processingIndex = i);
    // One at a time to keep memory use low.
    final saved = <PatrolFormPhoto>[];
    for (final file in picked) {
      final photo = await PatrolFormPhotoStore.compressAndSave(
        file.path,
        originalName: file.name,
        itemNo: item.itemNo ?? '',
      );
      if (photo != null) saved.add(photo);
    }
    if (!mounted) {
      unawaited(PatrolFormPhotoStore.deleteFiles(saved.map((p) => p.path)));
      return;
    }
    setState(() {
      _processingIndex = null;
      _photos.putIfAbsent(i, () => []).addAll(saved);
      _newPhotoPaths.addAll(saved.map((p) => p.path));
    });
    if (saved.length < picked.length) {
      CustomDialog.showAppToast('Some photos could not be processed.');
    }
  }

  void _removePhoto(int i, PatrolFormPhoto photo) {
    setState(() => _photos[i]?.remove(photo));
    if (_newPhotoPaths.remove(photo.path)) {
      // Never submitted anywhere — safe to delete right away.
      unawaited(PatrolFormPhotoStore.deleteFiles([photo.path]));
    } else {
      _removedPhotoPaths.add(photo.path);
    }
  }

  Future<void> _onPhotoTap(int i, PatrolFormPhoto photo) async {
    final action = await showBtmSheet(
      context,
      isScrollControlled: false,
      child: Builder(
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.zoom_in, color: AppColor.primary),
                title: 'View Photo'.bodyText(),
                onTap: () => Navigator.pop(sheetContext, 'view'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColor.dangerRed,
                ),
                title: 'Delete Photo'.bodyText(),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'view') {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _PhotoViewerPage(imagePath: photo.path),
        ),
      );
    } else if (action == 'delete') {
      _removePhoto(i, photo);
    }
  }

  Widget _buildAttachment(int i, PatrolFormItem item) {
    final photos = _photos[i] ?? const <PatrolFormPhoto>[];
    final isProcessing = _processingIndex == i;
    final tileDecoration = BoxDecoration(
      color: AppColor.lightGrey,
      borderRadius: BorderRadius.circular(Constants.borderRadiusSmall),
      border: Border.all(color: AppColor.darkGrey),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle(item, fallbackLabel: 'Attachment'),
        10.ph,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final photo in photos)
              GestureDetector(
                onTap: () => _onPhotoTap(i, photo),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(Constants.borderRadiusSmall),
                  child: Image.file(
                    File(photo.path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    // Decode at thumbnail size, not full resolution.
                    cacheWidth: 240,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      decoration: tileDecoration,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColor.textGrey,
                      ),
                    ),
                  ),
                ),
              ),
            if (isProcessing)
              Container(
                width: 80,
                height: 80,
                decoration: tileDecoration,
                padding: const EdgeInsets.all(28),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else if (photos.length < _maxPhotosPerItem)
              GestureDetector(
                onTap: _processingIndex == null
                    ? () => _onAddPhoto(i, item)
                    : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: tileDecoration,
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColor.textGrey,
                  ),
                ),
              ),
          ],
        ),
        6.ph,
        '${photos.length}/$_maxPhotosPerItem'.smallText(color: AppColor.textGrey),
      ],
    );
  }

  Widget _buildGroupTitle(PatrolFormItem item, {String fallbackLabel = ''}) {
    final label = item.labelText.isNotEmpty ? item.labelText : fallbackLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: label.bodyWithBoldText()),
            if (item.isMandatory) ' *'.smallText(color: AppColor.dangerRed),
          ],
        ),
        if (item.groupName.isNotEmpty) ...[
          4.ph,
          item.groupName.smallText(color: AppColor.textGrey),
        ],
      ],
    );
  }

  Widget _buildItem(int i, PatrolFormItem item) {
    switch (item.typeId) {
      case 'HEADER':
        return item.pageHeaderText.titleBoldText();
      case 'TEXT':
      case 'EMAIL':
      case 'SHORT TEXT':
      case 'LONG TEXT':
      case 'INTEGER':
      case 'DECIMAL':
        return AppTextField(
          key: ValueKey(i),
          initialValue: _values[i],
          labelText: item.labelText,
          hintText: item.placeholderText,
          isMust: item.isMandatory,
          moreThanOneLine: item.typeId == 'LONG TEXT',
          keyboardType: switch (item.typeId) {
            'INTEGER' => TextInputType.number,
            'DECIMAL' => const TextInputType.numberWithOptions(decimal: true),
            'EMAIL' => TextInputType.emailAddress,
            _ => null,
          },
          onChanged: (value) => _values[i] = value,
        );
      case 'DATETIME':
        return AppTextField(
          key: ValueKey('$i-${_values[i]}'),
          initialValue: _values[i],
          labelText: item.labelText,
          hintText: item.placeholderText,
          isMust: item.isMandatory,
          readOnly: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2300),
            );
            if (picked == null) return;
            setState(
              () => _values[i] = DateFormat('yyyy-MM-dd').format(picked),
            );
          },
        );
      case 'SINGLE CHOICE':
        final options = _groups[i] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupTitle(item),
            ...options.mapIndexed(
              (index, e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: RadioDot(selected: e[_groupItemValue] == true),
                title: Text(e[_groupItem]?.toString() ?? ''),
                onTap: () => setState(() {
                  for (final (j, o) in options.indexed) {
                    o[_groupItemValue] = j == index;
                  }
                }),
              ),
            ),
          ],
        );
      case 'MULTIPLE CHOICE':
        final options = _groups[i] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupTitle(item),
            ...options.map(
              (e) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(e[_groupItem]?.toString() ?? ''),
                value: e[_groupItemValue] == true,
                onChanged: (value) =>
                    setState(() => e[_groupItemValue] = value ?? false),
              ),
            ),
          ],
        );
      case 'DROPDOWN':
        final options = _groups[i] ?? const [];
        return AppTextField(
          showDropdown: true,
          isMust: item.isMandatory,
          labelText: item.labelText,
          hintText: item.placeholderText,
          initialValue: options
              .firstWhereOrNull((e) => e[_groupItemValue] == true)?[_groupItem]
              ?.toString(),
          filter: options
              .map((e) => DropdownMenuEntry(
                    value: e[_groupItem],
                    label: e[_groupItem]?.toString() ?? '',
                  ))
              .toList(),
          onDropChanged: (value) => setState(() {
            for (final o in options) {
              o[_groupItemValue] = o[_groupItem] == value;
            }
          }),
        );
      case 'NOTES':
        return Align(
          alignment: Alignment.topLeft,
          child: (item.formValue ?? '').bodyText(),
        );
      case 'LOGO':
        final url = item.fileUrl;
        if (url == null || url.isEmpty) return const SizedBox.shrink();
        return Image.network(
          url,
          height: 200.h,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      case _attachment:
        return _buildAttachment(i, item);
      default:
        // TERMSANDCONDITIONS etc. aren't supported here yet.
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkpoint = widget.checkpoint;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: widget.form.formName.titleBoldText(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (checkpoint != null) ...[
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
                      'Scan Code: ${checkpoint.scanCode}'.bodyWithBoldText(),
                      if (checkpoint.checkpointRemark.isNotEmpty) ...[
                        4.ph,
                        checkpoint.checkpointRemark
                            .smallText(color: AppColor.textGrey),
                      ],
                    ],
                  ),
                ),
                10.ph,
              ],
              for (final (i, item) in _items.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _buildItem(i, item),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
          child: CustomAppButton(
            title: widget.isEdit ? 'Update' : 'Submit',
            onTap: _onSubmit,
          ),
        ),
      ),
    );
  }
}

/// Single-choice indicator: the whole circle fills with the primary color
/// when selected (a plain radio only recolours its ring, hard to notice).
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColor.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColor.primary : AppColor.textGrey,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
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
