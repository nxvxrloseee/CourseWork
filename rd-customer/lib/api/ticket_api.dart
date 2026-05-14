import 'dart:convert';
import 'package:dio/dio.dart';
import 'api.dart';

class TicketApi {
  static Future<List<dynamic>> getMyTickets({
    String? status,
    int? categoryId,
    String? search,
    String? sort,
    bool excludeCompleted = false,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (sort != null) params['sort'] = sort;
    if (excludeCompleted) params['excludeCompleted'] = true;
    final res = await dio.get('/tickets/my', queryParameters: params);
    return res.data;
  }

  static Future<Map<String, dynamic>> getTicket(int id) async {
    final res = await dio.get('/tickets/$id');
    return res.data;
  }

  static Future<Map<String, dynamic>> createTicket({
    required int categoryId,
    required String title,
    required String description,
    String? selectedDatetime,
    List<String>? filePaths,
  }) async {
    final ticketData = {
      'categoryId': categoryId,
      'title': title,
      'description': description,
    };
    if (selectedDatetime != null) ticketData['selectedDatetime'] = selectedDatetime;

    final jsonString = jsonEncode(ticketData);

    final formData = FormData();
    formData.files.add(MapEntry(
      'ticket',
      MultipartFile.fromString(jsonString, contentType: DioMediaType('application', 'json')),
    ));

    if (filePaths != null) {
      for (final path in filePaths) {
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(path),
        ));
      }
    }

    final res = await dio.post('/tickets', data: formData,
      options: Options(contentType: 'multipart/form-data'));
    return res.data;
  }

  static Future<void> cancelTicket(int id) async {
    await dio.post('/tickets/$id/cancel');
  }

  static Future<Map<String, dynamic>> confirmPrices(int id) async {
    final res = await dio.post('/tickets/$id/confirm-prices');
    return res.data;
  }

  static Future<List<dynamic>> getStatusHistory(int id) async {
    final res = await dio.get('/tickets/$id/history');
    return res.data;
  }
}
