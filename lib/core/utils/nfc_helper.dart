import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager/ndef_record.dart';

class NfcScanUnavailableException implements Exception {
  NfcScanUnavailableException(this.availability);
  final NfcAvailability availability;

  @override
  String toString() => 'NFC unavailable: ${availability.name}';
}

class NfcHelper {
  NfcHelper._();

  static String _hex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  static String? _extractTagId(NfcTag tag) {
    final android = NfcTagAndroid.from(tag);
    if (android != null) return _hex(android.id);

    final mifareIos = MiFareIos.from(tag);
    if (mifareIos != null) return _hex(mifareIos.identifier);

    final iso7816Ios = Iso7816Ios.from(tag);
    if (iso7816Ios != null) return _hex(iso7816Ios.identifier);

    final iso15693Ios = Iso15693Ios.from(tag);
    if (iso15693Ios != null) return _hex(iso15693Ios.identifier);

    return null;
  }

  /// Reads the tag's NDEF message and decodes Record 1's text if it's an
  /// NDEF Well Known Text record (RTD "T") — returns null if the tag has no
  /// NDEF message, the message has no records, or Record 1 isn't a text
  /// record, so the caller can fall back to the tag's UID.
  static Future<String?> _readFirstNdefText(NfcTag tag) async {
    NdefMessage? message;

    final android = NdefAndroid.from(tag);
    if (android != null) {
      message = android.cachedNdefMessage ?? await android.getNdefMessage();
    } else {
      final ios = NdefIos.from(tag);
      if (ios != null) {
        message = ios.cachedNdefMessage ?? await ios.readNdef();
      }
    }

    final records = message?.records;
    if (records == null || records.isEmpty) return null;
    return _decodeTextRecord(records.first);
  }

  /// Decodes an NDEF Well Known Text record (RTD "T") payload per the NFC
  /// Forum Text Record Type Definition: payload[0] is a status byte whose
  /// top bit selects UTF-8/UTF-16 and whose low 6 bits give the length of
  /// the IANA language code that follows, then the text itself.
  static String? _decodeTextRecord(NdefRecord record) {
    if (record.typeNameFormat != TypeNameFormat.wellKnown) return null;
    if (record.type.length != 1 || record.type[0] != 0x54 /* 'T' */ ) {
      return null;
    }

    final payload = record.payload;
    if (payload.isEmpty) return null;

    final statusByte = payload[0];
    final isUtf16 = (statusByte & 0x80) != 0;
    final languageCodeLength = statusByte & 0x3F;
    final textStart = 1 + languageCodeLength;
    if (textStart > payload.length) return null;

    final textBytes = payload.sublist(textStart);
    try {
      if (isUtf16) {
        final codeUnits = <int>[];
        for (var i = 0; i + 1 < textBytes.length; i += 2) {
          codeUnits.add((textBytes[i] << 8) | textBytes[i + 1]);
        }
        return String.fromCharCodes(codeUnits);
      }
      return utf8.decode(textBytes);
    } catch (_) {
      return null;
    }
  }

  /// Starts an NFC session that stays open and calls [onTagDetected] with
  /// the scanned tag's content every time a tag is presented, until [stop]
  /// is called — used for continuous "tap to record" scanning rather than a
  /// single one-shot read.
  ///
  /// Each tap prefers Record 1 of the tag's NDEF message (decoded as text,
  /// per [_decodeTextRecord]) and only falls back to the tag's UID
  /// (uppercase hex) when the tag has no usable NDEF text.
  ///
  /// Throws [NfcScanUnavailableException] if NFC is off/unsupported so the
  /// caller can show the exact reason instead of a generic failure message.
  static Future<void> startContinuousScan({
    required void Function(String id) onTagDetected,
  }) async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      throw NfcScanUnavailableException(availability);
    }

    await NfcManager.instance.startSession(
      // iso18092 (NFC-F/FeliCa) is Android-only here: iOS requires a
      // declared systemCodes entitlement per tag issuer or the session
      // throws immediately, which this app doesn't have configured.
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        if (Platform.isAndroid) NfcPollingOption.iso18092,
      },
      noPlatformSoundsAndroid: true,
      // Keep the iOS session alive across multiple taps instead of
      // invalidating (and showing the "Done" sheet) after the first one.
      invalidateAfterFirstReadIos: false,
      onDiscovered: (NfcTag tag) async {
        final text = await _readFirstNdefText(tag);
        final value = (text != null && text.isNotEmpty)
            ? text
            : _extractTagId(tag);
        if (value != null) onTagDetected(value);
      },
    );
  }

  static Future<void> stop() => NfcManager.instance.stopSession();
}
