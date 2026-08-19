class AuthSessionTokens {
  const AuthSessionTokens({
    required this.accessToken,
    required this.expiresInSeconds,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final int expiresInSeconds;

  static AuthSessionTokens? fromJson(Object? value) {
    if (value is! Map) return null;
    final accessToken = value['access_token'];
    if (accessToken is! String || accessToken.trim().isEmpty) return null;
    final rawRefreshToken = value['refresh_token'];
    final refreshToken = rawRefreshToken is String && rawRefreshToken.isNotEmpty
        ? rawRefreshToken
        : null;
    final rawExpiresIn = value['expires_in'];
    final expiresIn = rawExpiresIn is num
        ? rawExpiresIn.toInt()
        : int.tryParse(rawExpiresIn?.toString() ?? '');
    return AuthSessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresIn != null && expiresIn > 0 ? expiresIn : 900,
    );
  }
}
