import 'api.dart';

class UserApi {
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await dio.get('/users/me');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? surname,
    String? name,
    String? patronymic,
  }) async {
    final res = await dio.put('/users/me', data: {
      'surname': ?surname,
      'name': ?name,
      'patronymic': ?patronymic,
    });
    return res.data;
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await dio.put('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
}
