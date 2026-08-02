/// Shared form validators used by register / email login / settings.
class FormValidators {
  FormValidators._();

  static String? requiredName(String? value, String emptyMessage) {
    if (value == null || value.trim().isEmpty) return emptyMessage;
    return null;
  }

  static String? email(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return emptyMessage;
    if (!v.contains('@') || !v.contains('.')) return invalidMessage;
    return null;
  }

  static String? passwordMin(
    String? value,
    String message, {
    int minLength = 6,
  }) {
    if (value == null || value.length < minLength) return message;
    return null;
  }

  static String? passwordMatch(
    String? value,
    String other,
    String mismatchMessage,
  ) {
    if (value != other) return mismatchMessage;
    return null;
  }
}
