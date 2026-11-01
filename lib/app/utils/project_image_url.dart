/// Resolve project media against the same API origin used for project data.
String? projectImageUrl(String? value, {required String apiBaseUrl, DateTime? updatedAt}) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final base = Uri.tryParse(apiBaseUrl);
  var uri = Uri.tryParse(raw);
  if (base == null || uri == null) return null;
  if (!uri.hasScheme) {
    uri = raw.startsWith('//')
        ? Uri.tryParse('${base.scheme}:$raw')
        : base.resolve(raw.startsWith('/') ? raw : '/$raw');
  }
  if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) return null;
  // Never alter signed/provider query parameters. New uploads already use unique URLs.
  if (updatedAt != null && !uri.hasQuery) {
    uri = uri.replace(queryParameters: {'v': '${updatedAt.millisecondsSinceEpoch}'});
  }
  return uri.toString();
}
