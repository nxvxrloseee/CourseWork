import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../api/notification_api.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _notifications = await NotificationApi.getNotifications();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    await NotificationApi.markAsRead(id);
    ref.read(unreadCountProvider.notifier).decrement();
    _load();
  }

  Future<void> _openNotification(Map<String, dynamic> n) async {
    final isRead = n['read'] == true;
    final ticketId = n['ticketId'];
    final messageId = n['messageId'];
    if (!isRead) {
      await NotificationApi.markAsRead(n['id']);
      ref.read(unreadCountProvider.notifier).decrement();
    }
    if (ticketId != null && mounted) {
      final query = messageId != null ? '?tab=chat&msg=$messageId' : '';
      context.push('/tickets/$ticketId$query');
    } else if (!isRead) {
      _load();
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationApi.markAllAsRead();
    ref.read(unreadCountProvider.notifier).set(0);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          TextButton(onPressed: _markAllAsRead, child: const Text('Прочитать все')),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty
          ? const Center(child: Text('Нет уведомлений', style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (_, i) {
                  final n = _notifications[i];
                  final isRead = n['read'] == true;
                  final hasLink = n['ticketId'] != null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
                    child: ListTile(
                      onTap: () => _openNotification(Map<String, dynamic>.from(n)),
                      leading: Icon(
                        isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(n['text'], style: TextStyle(
                        fontSize: 13,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600)),
                      subtitle: Row(
                        children: [
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(n['createdAt'])),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          if (hasLink) ...[
                            const Spacer(),
                            Text(
                              n['messageId'] != null ? '→ К сообщению' : '→ К заявке',
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ],
                      ),
                      trailing: hasLink ? const Icon(Icons.chevron_right, size: 18) : null,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
