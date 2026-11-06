import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:patrol/core/utils/patrol_form_photo.dart';

class PatrolCheckpointEntry {
  /// Route `checkpoint_id` matching the scanned scancode. Falls back to the
  /// raw NFC scan id when the patrol has no shift route (and for entries
  /// stored before checkpoint ids existed).
  final String checkpointId;

  /// The scanned NFC scancode, kept for display.
  final String scanCode;
  final DateTime timestamp;

  /// Digital form submitted at this checkpoint; [formAnswer] is the
  /// JSON-encoded list of answered `form_item`s, empty when there was none.
  final String formId;
  final String formName;
  final String formAnswer;

  /// `digitalFormDetail.id` — sent as `org_form_id` on upload.
  final String orgFormId;

  /// JSON-encoded [PatrolFormPhoto] list from the form's ATTACHMENT items;
  /// empty when none.
  final String formPhotos;

  /// The checkpoint was skipped (a later one was scanned first); its form
  /// fields then hold the `digitalFormCheckpointSkip` answers.
  final bool isSkip;

  PatrolCheckpointEntry({
    required this.checkpointId,
    this.scanCode = '',
    DateTime? timestamp,
    this.formId = '',
    this.formName = '',
    this.formAnswer = '',
    this.orgFormId = '',
    this.formPhotos = '',
    this.isSkip = false,
  }) : timestamp = timestamp ?? DateTime.now();

  String get displayCode => scanCode.isNotEmpty ? scanCode : checkpointId;

  bool get hasForm => formAnswer.isNotEmpty;

  List<PatrolFormPhoto> get photos => decodePatrolFormPhotos(formPhotos);

  PatrolCheckpointEntry copyWith({String? formAnswer, String? formPhotos}) {
    return PatrolCheckpointEntry(
      checkpointId: checkpointId,
      scanCode: scanCode,
      timestamp: timestamp,
      formId: formId,
      formName: formName,
      formAnswer: formAnswer ?? this.formAnswer,
      orgFormId: orgFormId,
      formPhotos: formPhotos ?? this.formPhotos,
      isSkip: isSkip,
    );
  }

  /// Decoded [formAnswer]; empty when there's no form or it's malformed.
  List<Map<String, dynamic>> get decodedFormAnswer {
    if (formAnswer.isEmpty) return [];
    try {
      final decoded = jsonDecode(formAnswer);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class PatrolCheckpointStorage {
  PatrolCheckpointStorage._();
  static final PatrolCheckpointStorage instance = PatrolCheckpointStorage._();

  static const _boxName = 'patrol_checkpoints';

  Box<PatrolCheckpointEntry>? _box;

  /// Newest first.
  List<PatrolCheckpointEntry> get entries {
    final values = _box?.values.toList() ?? [];
    return values.reversed.toList();
  }

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(PatrolCheckpointEntryAdapter().typeId)) {
      Hive.registerAdapter(PatrolCheckpointEntryAdapter());
    }
    try {
      _box = _box ?? await Hive.openBox<PatrolCheckpointEntry>(_boxName);
    } catch (_) {}
  }

  Future<void> add(PatrolCheckpointEntry entry) async {
    await _box?.add(entry);
  }

  Future<void> delete(PatrolCheckpointEntry entry) async {
    final key = _keyOf(entry);
    if (key != null) await _box?.delete(key);
  }

  Future<void> updateForm(
    PatrolCheckpointEntry entry, {
    required String formAnswer,
    required String formPhotos,
  }) async {
    final key = _keyOf(entry);
    if (key == null) return;
    await _box?.put(
      key,
      entry.copyWith(formAnswer: formAnswer, formPhotos: formPhotos),
    );
  }

  Future<void> clear() async {
    await _box?.clear();
  }

  dynamic _keyOf(PatrolCheckpointEntry entry) {
    final box = _box;
    if (box == null) return null;
    return box.keys.firstWhere(
      (k) => identical(box.get(k), entry),
      orElse: () => null,
    );
  }
}

class PatrolCheckpointEntryAdapter extends TypeAdapter<PatrolCheckpointEntry> {
  @override
  final int typeId = 1;

  @override
  PatrolCheckpointEntry read(BinaryReader reader) {
    final checkpointId = reader.readString();
    reader.readString(); // Legacy remark slot — no longer used.
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    // Fields below were appended later — entries written by older builds
    // end here, so only read them when bytes remain.
    final hasExtra = reader.availableBytes > 0;
    final scanCode = hasExtra ? reader.readString() : '';
    final formId = hasExtra ? reader.readString() : '';
    final formName = hasExtra ? reader.readString() : '';
    final formAnswer = hasExtra ? reader.readString() : '';
    final orgFormId = reader.availableBytes > 0 ? reader.readString() : '';
    final formPhotos = reader.availableBytes > 0 ? reader.readString() : '';
    final isSkip = reader.availableBytes > 0 ? reader.readBool() : false;
    return PatrolCheckpointEntry(
      checkpointId: checkpointId,
      timestamp: timestamp,
      scanCode: scanCode,
      formId: formId,
      formName: formName,
      formAnswer: formAnswer,
      orgFormId: orgFormId,
      formPhotos: formPhotos,
      isSkip: isSkip,
    );
  }

  @override
  void write(BinaryWriter writer, PatrolCheckpointEntry obj) {
    writer.writeString(obj.checkpointId);
    // Legacy remark slot: kept as an empty placeholder so entries written
    // by older builds (which store a remark here) still read back correctly.
    writer.writeString('');
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeString(obj.scanCode);
    writer.writeString(obj.formId);
    writer.writeString(obj.formName);
    writer.writeString(obj.formAnswer);
    writer.writeString(obj.orgFormId);
    writer.writeString(obj.formPhotos);
    writer.writeBool(obj.isSkip);
  }
}
