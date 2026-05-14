import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/notification_api.dart';

class UnreadCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
  void decrement() => state--;

  Future<void> refresh() async {
    try {
      final count = await NotificationApi.getUnreadCount();
      state = count;
    } catch (_) {}
  }
}

final unreadCountProvider = NotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);
