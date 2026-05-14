import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../api/ticket_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await TicketApi.getMyTickets();
      setState(() {
        _tickets = all.where((t) =>
          t['status'] == 'Завершена' || t['status'] == 'Отменена').toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История заявок')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _tickets.isEmpty
          ? const Center(child: Text('Нет завершённых заявок', style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tickets.length,
                itemBuilder: (_, i) {
                  final t = _tickets[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => context.push('/tickets/${t['id']}'),
                      title: Text('#${t['id']} ${t['title']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(DateTime.parse(t['createdAt'])),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: t['status'] == 'Завершена' ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(12)),
                        child: Text(t['status'], style: TextStyle(
                          fontSize: 11,
                          color: t['status'] == 'Завершена' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
