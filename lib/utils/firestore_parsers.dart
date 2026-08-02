import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared Firestore map readers — keeps models thin and consistent.
DateTime? readTimestamp(Object? raw) =>
    raw is Timestamp ? raw.toDate() : null;

double readDouble(Object? raw, [double fallback = 0]) =>
    (raw as num?)?.toDouble() ?? fallback;

int readInt(Object? raw, [int fallback = 0]) =>
    (raw as num?)?.toInt() ?? fallback;

String readString(Object? raw, [String fallback = '']) =>
    raw as String? ?? fallback;

bool readBool(Object? raw, [bool fallback = false]) =>
    raw as bool? ?? fallback;

List<Map<String, dynamic>> readMapList(Object? raw) {
  if (raw is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      out.add(item);
    } else if (item is Map) {
      out.add(Map<String, dynamic>.from(item));
    }
  }
  return out;
}
