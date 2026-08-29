import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  String? _token;

  // El login pantalla-de-login no pasa por acá (nunca hay _token puesto
  // todavía), así que un 401 solo puede significar que el token guardado
  // expiró o fue revocado a mitad de sesión. `_sessionExpiredNotified` evita
  // disparar el logout/redirección varias veces cuando varias peticiones en
  // vuelo (p. ej. las que arma una pantalla al abrir) devuelven 401 casi
  // juntas; se resetea en `setToken()` al iniciar sesión de nuevo.
  static void Function()? onSessionExpired;
  bool _sessionExpiredNotified = false;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 &&
            _token != null &&
            !_sessionExpiredNotified) {
          _sessionExpiredNotified = true;
          onSessionExpired?.call();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  void setToken(String token) {
    _token = token;
    _sessionExpiredNotified = false;
  }

  void clearToken() {
    _token = null;
  }

  String? get token => _token;

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}