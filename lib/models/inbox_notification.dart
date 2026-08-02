import '../l10n/app_locale.dart';
import '../utils/firestore_parsers.dart';

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.createdAt,
    this.data = const {},
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  factory InboxNotification.fromMap(String id, Map<String, dynamic> data) {
    final titleBn = data['titleBn'] as String?;
    final titleEn = data['titleEn'] as String?;
    final bodyBn = data['bodyBn'] as String?;
    final bodyEn = data['bodyEn'] as String?;
    return InboxNotification(
      id: id,
      title: (titleBn != null && titleEn != null)
          ? AppLocale.pick(titleBn, titleEn)
          : readString(data['title'], 'Mass Manager'),
      body: (bodyBn != null && bodyEn != null)
          ? AppLocale.pick(bodyBn, bodyEn)
          : readString(data['body'], ''),
      type: readString(data['type'], 'general'),
      read: data['read'] == true,
      createdAt: readTimestamp(data['createdAt']),
      data: (data['data'] is Map)
          ? Map<String, dynamic>.from(data['data'] as Map)
          : const {},
    );
  }
}
