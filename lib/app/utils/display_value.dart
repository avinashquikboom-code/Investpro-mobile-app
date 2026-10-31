/// Formatting only: IDs used by API requests and navigation remain unchanged.
class DisplayValue {
  static String text(Object? value, {String fallback = 'N/A'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static Map<String, String> ids(Map<String, dynamic> json) {
    final result = <String, String>{};
    final cached = json['recordIds'];
    if (cached is Map) {
      for (final entry in cached.entries) {
        if (entry.value is String) result[entry.key.toString()] = entry.value as String;
      }
    }
    for (final entry in json.entries) {
      if ((entry.key == 'id' || entry.key.endsWith('Id')) && entry.value is String && (entry.value as String).isNotEmpty) result[entry.key] = entry.value as String;
      if (['user', 'investor', 'project', 'investment', 'wallet', 'payment', 'bankAccount'].contains(entry.key) && entry.value is Map) {
        final id = (entry.value as Map)['id'];
        if (id is String && id.isNotEmpty) result['${entry.key}Id'] = id;
      }
    }
    return result;
  }

  static String reference(Object? value, {Object? internalId}) => text(value);
}
