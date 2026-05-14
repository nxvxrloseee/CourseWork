import 'api.dart';

class CategoryApi {
  static Future<List<dynamic>> getCategories() async {
    final res = await dio.get('/categories');
    return res.data;
  }
}
