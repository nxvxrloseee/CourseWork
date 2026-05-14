import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/category_api.dart';
import '../api/service_api.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabC;
  List<dynamic> _categories = [];
  List<dynamic> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cats = await CategoryApi.getCategories();
      final svcs = await ServiceApi.getActiveServices();
      if (!mounted) return;
      setState(() { _categories = cats; _services = svcs; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Не удалось загрузить данные'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RepairDesk'),
        bottom: TabBar(controller: _tabC, isScrollable: true, tabs: const [
          Tab(text: 'О нас'),
          Tab(text: 'Категории'),
          Tab(text: 'Прайс-лист'),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Войти'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Регистрация'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _load, child: const Text('Повторить')),
                  ],
                ))
              : TabBarView(controller: _tabC, children: [
                  _buildAbout(),
                  _buildCategories(),
                  _buildPriceList(),
                ]),
    );
  }

  Widget _buildAbout() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.build_circle, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ИП RepairDesk',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Ремонт техники с гарантией',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Индивидуальный предприниматель, специализирующийся на диагностике, '
                'ремонте и обслуживании смартфонов, ноутбуков, планшетов и другой '
                'электронной техники. Работаем официально, выдаём чеки, даём гарантию '
                'на выполненные работы.',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Что мы делаем', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        _featureCard(Icons.search, 'Диагностика', 'Точное определение причины неисправности перед началом ремонта.'),
        _featureCard(Icons.memory, 'Замена компонентов', 'Аккумуляторы, экраны, разъёмы, материнские платы — оригинальные и совместимые запчасти.'),
        _featureCard(Icons.cleaning_services, 'Чистка и профилактика', 'Удаление пыли, замена термопасты, профилактика системы охлаждения.'),
        _featureCard(Icons.restore, 'Восстановление данных', 'Спасение информации с повреждённых накопителей и устройств.'),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Почему мы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        _featureCard(Icons.price_check, 'Прозрачные цены',
            'Полный прайс-лист доступен прямо в приложении. Никаких скрытых платежей.'),
        _featureCard(Icons.verified_user, 'Подтверждение заказчиком',
            'Заказчик подтверждает согласие со списком услуг и ценами перед закрытием заявки.'),
        _featureCard(Icons.notifications_active, 'Статус в реальном времени',
            'Уведомления на каждом этапе: приняли в работу, готово, можно забирать.'),
        _featureCard(Icons.chat_bubble_outline, 'Чат с мастером',
            'Прямая связь с исполнителем без звонков на горячую линию.'),
        _featureCard(Icons.shield_outlined, 'Гарантия 30 дней',
            'На все выполненные работы предоставляется гарантия. Бесплатное повторное обслуживание при необходимости.'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Контакты', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _contactRow(Icons.phone, '+7 (495) 123-45-67'),
                _contactRow(Icons.email_outlined, 'support@repairdesk.ru'),
                _contactRow(Icons.location_on_outlined, 'г. Москва, ул. Примерная, д. 1, оф. 12'),
                _contactRow(Icons.access_time, 'Пн–Пт: 10:00–20:00, Сб: 11:00–18:00'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'ИП RepairDesk · ИНН 770000000000 · ОГРНИП 000000000000000',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _featureCard(IconData icon, String title, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return const Center(child: Text('Категории не настроены', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = _categories[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.build_outlined),
            title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        );
      },
    );
  }

  Widget _buildPriceList() {
    if (_services.isEmpty) {
      return const Center(child: Text('Прайс-лист пуст', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = _services[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (s['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(s['description'],
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('${s['price']} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }
}
