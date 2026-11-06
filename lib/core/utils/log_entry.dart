import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

enum LogType { network, error, info }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final String typeName;

  LogEntry({required this.message, required this.typeName, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();

  LogType get type => LogType.values.firstWhere((e) => e.name == typeName);

  String get formatted {
    final ts = '[${timestamp.toString().substring(0, 19)}]';
    return '$ts $message';
  }

  factory LogEntry.create({required String message, required LogType type}) => LogEntry(message: message, typeName: type.name);
}

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const _boxName = 'app_logs';

  Box<LogEntry>? _logs;

  List<LogEntry> get logs {
    final box = _logs?.values.toList();
    if (box?.isNotEmpty == true) {
      return box!;
    }
    return [];
  }

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LogEntryAdapter());
    try {
      _logs = await Hive.openBox<LogEntry>(_boxName);
    } catch (_) {}
  }

  Future<void> log(String message, {LogType type = LogType.info}) async {
    final entry = LogEntry.create(message: message, type: type);
    final box = Hive.box<LogEntry>(_boxName);
    await box.add(entry);
  }

  void network(String message) => log(message, type: LogType.network);
  void error(String message) => log(message, type: LogType.error);
  void info(String message) => log(message, type: LogType.info);

  Future<void> clear() async {
    final box = Hive.box<LogEntry>(_boxName);
    await box.clear();
  }

  Future<void> dispose() async {
    final box = Hive.box<LogEntry>(_boxName);
    await box.close();
  }
}

class LogEntryAdapter extends TypeAdapter<LogEntry> {
  @override
  final int typeId = 0;

  @override
  LogEntry read(BinaryReader reader) {
    return LogEntry(timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()), message: reader.readString(), typeName: reader.readString());
  }

  @override
  void write(BinaryWriter writer, LogEntry obj) {
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeString(obj.message);
    writer.writeString(obj.typeName);
  }
}
