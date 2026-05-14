import 'api.dart';

class NotificationApi {
  static Future<List<dynamic>> getNotifications() async {
    final res = await dio.get('/notifications');
    return res.data;
  }

  static Future<int> getUnreadCount() async {
    final res = await dio.get('/notifications/unread-count');
    return res.data['count'];
  }

  static Future<void> markAsRead(int id) async {
    await dio.patch('/notifications/$id/read');
  }

  static Future<void> markAllAsRead() async {
    await dio.patch('/notifications/read-all');
  }
}
