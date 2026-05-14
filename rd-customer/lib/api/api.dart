import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

final dio = Dio();

/// Converts backend media URLs to absolute URLs.
/// Backend returns /api/files/filename — prepend base host.
String fixMediaUrl(String url) {
  if (url.startsWith('/api/')) {
    final base = dotenv.env['baseUrl']!;
    final host = base.replaceAll('/api', '');
    return '$host$url';
  }
  return url;
}

void configureDio() {
  dio.options.baseUrl = dotenv.env['baseUrl']!;
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await storage.delete(key: 'token');
      }
      handler.next(error);
    },
  ));
}
