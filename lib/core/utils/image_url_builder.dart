String coverUrl(String baseUrl, String coverFile) {
  final trimmed = coverFile.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    final uri = Uri.parse(trimmed);
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final base = Uri.parse(baseUrl);
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: uri.path,
        query: uri.query,
        fragment: uri.fragment,
      ).toString();
    }
    return trimmed;
  }
  if (trimmed.startsWith('/api/harmonix/apps/covers/')) {
    return '$baseUrl$trimmed';
  }
  if (trimmed.startsWith('/')) {
    return '$baseUrl$trimmed';
  }
  return '$baseUrl/api/harmonix/apps/covers/$trimmed';
}

String streamUrl(String baseUrl, String trackId) {
  final trimmed = trackId.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    final uri = Uri.parse(trimmed);
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final base = Uri.parse(baseUrl);
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: uri.path,
        query: uri.query,
        fragment: uri.fragment,
      ).toString();
    }
    return trimmed;
  }
  if (trimmed.startsWith('/api/harmonix/apps/stream/')) {
    return '$baseUrl$trimmed';
  }
  if (trimmed.startsWith('/')) {
    return '$baseUrl$trimmed';
  }
  return '$baseUrl/api/harmonix/apps/stream/$trimmed';
}
