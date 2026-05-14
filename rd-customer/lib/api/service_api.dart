import 'api.dart';

class ServiceApi {
  static Future<List<dynamic>> getActiveServices() async {
    final res = await dio.get('/services');
    return res.data;
  }
}
