/// Credentials belong to one Sonora origin, including its protocol and port.
bool sameServerOrigin(String server, Uri target) {
  final base =
      Uri.tryParse(server.contains('://') ? server : 'https://$server');
  return base != null &&
      base.scheme == target.scheme &&
      base.host.toLowerCase() == target.host.toLowerCase() &&
      base.port == target.port;
}

Map<String, String>? serverHeaders(String server, String url, String? token) =>
    token != null &&
            token.isNotEmpty &&
            sameServerOrigin(server, Uri.parse(url))
        ? {'Authorization': 'Bearer $token'}
        : null;
