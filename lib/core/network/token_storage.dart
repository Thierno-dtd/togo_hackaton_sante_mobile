import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyAccessToken  = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId       = 'user_id';

  // ── Sauvegarder ──
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken,  value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      if (userId != null)
        _storage.write(key: _keyUserId, value: userId),
    ]);
  }

  // ── Lire ──
  Future<String?> getAccessToken()  => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<String?> getUserId()       => _storage.read(key: _keyUserId);

  // ── Vérifier si connecté ──
  Future<bool> hasValidTokens() async {
    final access  = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && access.isNotEmpty &&
           refresh != null && refresh.isNotEmpty;
  }

  // ── Mettre à jour l'access token seul (après refresh) ──
  Future<void> updateAccessToken(String newToken) async {
    await _storage.write(key: _keyAccessToken, value: newToken);
  }

  // ── Supprimer tout (logout) ──
  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserId),
    ]);
  }
}