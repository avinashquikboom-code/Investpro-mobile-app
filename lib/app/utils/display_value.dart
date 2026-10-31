/// Display IDs are supplied by PostgreSQL sequences; internal keys remain untouched.
class DisplayValue {
  static final _registered = <String, String>{};
  static final _uuid = RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', caseSensitive: false);
  static void register(Object? envelope) {
    if (envelope is! Map || envelope['displayIds'] is! Map) return;
    for (final entry in (envelope['displayIds'] as Map).entries) {
      if (entry.value is int && (entry.value as int) > 0) _registered[entry.key.toString()] = entry.value.toString();
    }
  }
  static String id(Object? value, {String fallback = 'N/A'}) {
    if (value is int && value > 0) return value.toString();
    if (value is! String || value.isEmpty) return fallback;
    return _registered[value] ?? (RegExp(r'^\d+$').hasMatch(value) ? value : fallback);
  }
  static String text(Object? value, {String fallback = 'N/A'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || _uuid.hasMatch(text) ? fallback : text;
  }
  static Map<String, String> ids(Map<String, dynamic> json) {
    final result = <String, String>{};
    final cached = json['recordIds'];
    if (cached is Map) { for (final entry in cached.entries) { result[entry.key.toString()] = id(entry.value); } }
    for (final entry in json.entries) {
      final key = entry.key;
      if (key == 'id') {
        final own = json['displayId'];
        if (entry.value is String && own is int) _registered[entry.value as String] = own.toString();
        result[key] = id(own ?? entry.value);
      }
      else if (key.endsWith('Id') && key != 'displayId' && !key.endsWith('DisplayId')) { result[key] = id(json['${key.substring(0,key.length-2)}DisplayId'] ?? entry.value); }
      if (['user','investor','project','investment','wallet','payment','bankAccount','adminProfile'].contains(key) && entry.value is Map) {
        final nested = entry.value as Map;
        result['${key}Id'] = id(nested['displayId'] ?? nested['id']);
      }
    }
    for (final relation in ['payments','returnSchedules']) {
      final rows = json[relation];
      if (rows is List) { for (var i=0; i<rows.length; i++) {
        if (rows[i] is Map) { result['${relation == 'payments' ? 'payment' : 'returnSchedule'}${i+1}Id'] = id(rows[i]['displayId'] ?? rows[i]['id']); }
      } }
    }
    return result;
  }
  static String reference(Object? value, {Object? internalId}) {
    final raw = value?.toString() ?? '';
    final match = _uuid.firstMatch(raw);
    if (match != null) return id(internalId ?? match.group(0));
    return value == internalId ? id(value) : text(value);
  }
}
