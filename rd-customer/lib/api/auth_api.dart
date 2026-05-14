import 'api.dart';

class AuthApi {
  static Future<Map<String, dynamic>> register({
    required String surname,
    required String name,
    String? patronymic,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await dio.post('/auth/register', data: {
      'surname': surname,
      'name': name,
      'patronymic': patronymic,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return res.data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data;
  }

  static Future<void> logout() async {
    await dio.post('/auth/logout');
  }
}
