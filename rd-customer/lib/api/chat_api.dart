import 'api.dart';

class ChatApi {
  static Future<List<dynamic>> getMessages(int ticketId) async {
    final res = await dio.get('/chat/$ticketId');
    return res.data;
  }

  static Future<Map<String, dynamic>> sendMessage(int ticketId, String text) async {
    final res = await dio.post('/chat/send', data: {
      'ticketId': ticketId,
      'text': text,
    });
    return res.data;
  }
}
