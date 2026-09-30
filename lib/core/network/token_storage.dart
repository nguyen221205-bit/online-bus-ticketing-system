import 'package:shared_preferences/shared_preferences.dart';

/// Manages authentication tokens with SharedPreferences and in-memory cache
class TokenStorage {
  static const String _accessTokenKey = 'vexgo_access_token';
  static const String _refreshTokenKey = 'vexgo_refresh_token';

  static String? _cachedAccessToken;

  /// Fast synchronous access to cached token
  static String? get currentToken => _cachedAccessToken;

  /// Initialize token from disk into memory
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedAccessToken = prefs.getString(_accessTokenKey);
  }

  /// Get current access token
  static Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedAccessToken = prefs.getString(_accessTokenKey);
    return _cachedAccessToken;
  }

  /// Get current refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Save access and refresh tokens
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Clear all stored tokens upon logout
  static Future<void> clearTokens() async {
    _cachedAccessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
