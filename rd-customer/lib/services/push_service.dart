import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../api/api.dart';

class PushService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static StompClient? _stompClient;
  static int _notifId = 0;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      'repairdesk_notifications',
      'RepairDesk',
      description: 'Уведомления RepairDesk',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> connect() async {
    disconnect();

    final token = await storage.read(key: 'token');
    if (token == null) return;

    final wsUrl = dotenv.env['wsUrl']!;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          _stompClient!.subscribe(
            destination: '/user/queue/notifications',
            callback: (frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                _showNotification(data['text'] ?? 'Новое уведомление');
              }
            },
          );
        },
        onWebSocketError: (_) {},
        onStompError: (_) {},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stompClient!.activate();
  }

  static void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  static Future<void> _showNotification(String text) async {
    const androidDetails = AndroidNotificationDetails(
      'repairdesk_notifications',
      'RepairDesk',
      channelDescription: 'Уведомления RepairDesk',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(id: _notifId++, title: 'RepairDesk', body: text, notificationDetails: details);
  }
}
