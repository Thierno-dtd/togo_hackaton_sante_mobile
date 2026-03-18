import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'token_storage.dart';

// ════════════════════════════════════════════════════════════
// Résultat générique d'un appel API
// ════════════════════════════════════════════════════════════
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final ApiError? error;

  const ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.error,
  });

  factory ApiResponse.ok(T data, {String? message, int? statusCode}) =>
      ApiResponse._(success: true, data: data, message: message, statusCode: statusCode);

  factory ApiResponse.fail(ApiError error, {int? statusCode}) =>
      ApiResponse._(success: false, error: error, statusCode: statusCode);

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound     => statusCode == 404;
  bool get isServerError  => statusCode != null && statusCode! >= 500;
}

class ApiError {
  final String message;
  final String? code;
  final Map<String, List<String>>? fieldErrors; // erreurs de validation

  const ApiError({required this.message, this.code, this.fieldErrors});

  @override
  String toString() => message;
}

// ════════════════════════════════════════════════════════════
// Client HTTP principal
// ════════════════════════════════════════════════════════════
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _init();
  }

  late final Dio _dio;
  late final Dio _refreshDio; // Dio séparé pour le refresh (sans intercepteur)
  final _tokenStorage = TokenStorage();

  // Flag pour éviter les boucles de refresh simultanés
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshCallbacks = [];

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '1.0.0',
        'X-Platform': defaultTargetPlatform.name,
      },
    ));

    // Dio séparé sans intercepteur pour les appels de refresh
    _refreshDio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_tokenStorage, _dio, _refreshDio, this),
      if (kDebugMode) _LogInterceptor(),
    ]);
  }

  // ── GET ──
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParams);
      return ApiResponse.ok(
        fromJson != null ? fromJson(res.data) : res.data as T,
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ── POST ──
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.post(path, data: data);
      return ApiResponse.ok(
        fromJson != null ? fromJson(res.data) : res.data as T,
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ── PUT ──
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.put(path, data: data);
      return ApiResponse.ok(
        fromJson != null ? fromJson(res.data) : res.data as T,
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ── PATCH ──
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.patch(path, data: data);
      return ApiResponse.ok(
        fromJson != null ? fromJson(res.data) : res.data as T,
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ── DELETE ──
  Future<ApiResponse<void>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return ApiResponse.ok(null, statusCode: res.statusCode);
    } on DioException catch (e) {
      return _handleError<void>(e);
    }
  }

  // ── Upload multipart (images, documents) ──
  Future<ApiResponse<T>> upload<T>(
    String path,
    FormData formData, {
    T Function(dynamic)? fromJson,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return ApiResponse.ok(
        fromJson != null ? fromJson(res.data) : res.data as T,
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ── Gestion centralisée des erreurs Dio ──
  ApiResponse<T> _handleError<T>(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse.fail(
          const ApiError(
            message: 'Délai de connexion dépassé. Vérifiez votre réseau.',
            code: 'TIMEOUT',
          ),
          statusCode: statusCode,
        );

      case DioExceptionType.connectionError:
        return ApiResponse.fail(
          const ApiError(
            message: 'Pas de connexion internet.',
            code: 'NO_INTERNET',
          ),
        );

      case DioExceptionType.badResponse:
        return _handleHttpError<T>(statusCode, data);

      default:
        return ApiResponse.fail(
          ApiError(message: e.message ?? 'Une erreur inattendue est survenue.'),
          statusCode: statusCode,
        );
    }
  }

  ApiResponse<T> _handleHttpError<T>(int? statusCode, dynamic data) {
    String message;
    String? code;
    Map<String, List<String>>? fieldErrors;

    // Parser le corps de l'erreur (format standard attendu de l'API)
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? _defaultMessage(statusCode);
      code = data['code']?.toString();
      if (data['errors'] is Map) {
        fieldErrors = (data['errors'] as Map).map(
          (k, v) => MapEntry(k.toString(),
            (v is List ? v : [v]).map((e) => e.toString()).toList()),
        );
      }
    } else {
      message = _defaultMessage(statusCode);
    }

    return ApiResponse.fail(
      ApiError(message: message, code: code, fieldErrors: fieldErrors),
      statusCode: statusCode,
    );
  }

  String _defaultMessage(int? code) {
    switch (code) {
      case 400: return 'Requête invalide.';
      case 401: return 'Session expirée. Veuillez vous reconnecter.';
      case 403: return 'Accès refusé.';
      case 404: return 'Ressource introuvable.';
      case 409: return 'Conflit de données.';
      case 422: return 'Données invalides.';
      case 429: return 'Trop de requêtes. Veuillez patienter.';
      case 500: return 'Erreur serveur. Réessayez plus tard.';
      case 503: return 'Service indisponible. Réessayez plus tard.';
      default:  return 'Une erreur est survenue.';
    }
  }

  // Appelé par l'intercepteur pour refresher le token
  Future<String?> refreshAccessToken() async {
    if (_isRefreshing) {
      // Attendre que le refresh en cours se termine
      return Future(() async {
        final completer = Completer<String>();
        _refreshCallbacks.add((token) => completer.complete(token));
        return completer.future;
      });
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return null;

      final res = await _refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = res.data['access_token'] as String;
      final newRefreshToken = res.data['refresh_token'] as String?;

      await _tokenStorage.updateAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
      }

      // Notifier les requêtes en attente
      for (final cb in _refreshCallbacks) {
        cb(newAccessToken);
      }
      _refreshCallbacks.clear();

      return newAccessToken;
    } catch (_) {
      _refreshCallbacks.clear();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}

// ════════════════════════════════════════════════════════════
// ─── Intercepteur d'authentification ───
// ════════════════════════════════════════════════════════════
class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;
  final Dio _refreshDio;
  final ApiClient _apiClient;

  _AuthInterceptor(this._tokenStorage, this._dio, this._refreshDio, this._apiClient);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Routes publiques (pas de token nécessaire)
    final publicRoutes = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.refreshToken,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.googleAuth,
    ];

    if (publicRoutes.any((r) => options.path.endsWith(r))) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si 401 → tenter un refresh automatique
    if (err.response?.statusCode == 401) {
      final newToken = await _apiClient.refreshAccessToken();

      if (newToken != null) {
        // Retry la requête originale avec le nouveau token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final res = await _dio.fetch(opts);
          return handler.resolve(res);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Refresh échoué → forcer logout
        await _tokenStorage.clearAll();
        // AppProvider.navigatorKey permet de naviguer vers LoginPage
        // (géré dans AppProvider.logout())
      }
    }
    handler.next(err);
  }
}

// ════════════════════════════════════════════════════════════
// ─── Logger en mode debug ───
// ════════════════════════════════════════════════════════════
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    if (options.data != null) debugPrint('  Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('✗ ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('  ${err.response?.data}');
    handler.next(err);
  }
}

// Helper pour les Completers dans le refresh
class Completer<T> {
  late T Function(T) _onComplete;
  void complete(T value) => _onComplete(value);
  Future<T> get future async => _onComplete as T;
}