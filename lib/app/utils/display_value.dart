/// Display-only values; internal identifiers remain in models for API/navigation.
class DisplayValue {
  static final _uuid = RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', caseSensitive: false);
  static String text(Object? value, {String fallback = 'N/A'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || _uuid.hasMatch(text) ? fallback : text;
  }
  static String reference(Object? value, {Object? internalId}) => value == internalId ? 'N/A' : text(value);
}
