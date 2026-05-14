import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../api/ticket_api.dart';
import '../api/category_api.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<dynamic> _tickets = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  String? _statusFilter;
  int? _categoryFilter;
  final _searchController = TextEditingController();
  String _search = '';
  String _sort = 'createdAtDesc';

  static const _statuses = ['Новая', 'В работе', 'Ожидает устройство', 'В ремонте', 'Готово', 'Отменена'];
  static const _sortOptions = {
    'createdAtDesc': 'Дата: новые → старые',
    'createdAtAsc': 'Дата: старые → новые',
    'idDesc': 'Номер: новые → старые',
    'idAsc': 'Номер: старые → новые',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
    CategoryApi.getCategories().then((c) => setState(() => _categories = c));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tickets = await TicketApi.getMyTickets(
        status: _statusFilter,
        categoryId: _categoryFilter,
        search: _search.isNotEmpty ? _search : null,
        sort: _sort,
        excludeCompleted: true,
      );
      setState(() => _tickets = tickets);
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Новая' => Colors.blue,
      'В работе' => Colors.orange,
      'Ожидает устройство' => Colors.purple,
      'В ремонте' => Colors.deepOrange,
      'Готово' => Colors.teal,
      'Завершена' => Colors.green,
      'Отменена' => Colors.red,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заявки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tickets/create').then((_) => _load()),
        icon: const Icon(Icons.add),
        label: const Text('Новая заявка'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Номер, заголовок, описание, мастер, категория...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                          _load();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                setState(() => _search = v);
              },
              onSubmitted: (_) => _load(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
                ? const Center(child: Text('Заявок пока нет', style: TextStyle(color: Colors.grey)))
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
                      onTap: () => context.push('/tickets/${t['id']}').then((_) => _load()),
                      title: Text('#${t['id']} ${t['title']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(t['description'], maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(t['status']).withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(t['status'], style: TextStyle(
                                  fontSize: 11, color: _statusColor(t['status']), fontWeight: FontWeight.w600)),
                              ),
                              const Spacer(),
                              Text(DateFormat('dd.MM.yyyy').format(DateTime.parse(t['createdAt'])),
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Фильтры', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(labelText: 'Статус', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все')),
                ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) => setState(() => _statusFilter = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _categoryFilter,
              decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все')),
                ..._categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))),
              ],
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Сортировка', border: OutlineInputBorder()),
              items: _sortOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _sort = v ?? 'createdAtDesc'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () { Navigator.pop(context); _load(); },
                child: const Text('Применить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
