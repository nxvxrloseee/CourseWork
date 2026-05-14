import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../api/api.dart';
import '../api/ticket_api.dart';
import '../api/chat_api.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  final String? initialTab;
  final int? targetMessageId;
  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.initialTab,
    this.targetMessageId,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  List<dynamic> _history = [];
  late TabController _tabC;
  final _msgC = TextEditingController();
  bool _loading = true;
  StompClient? _stompClient;
  final ScrollController _chatScrollC = ScrollController();
  final Map<int, GlobalKey> _messageKeys = {};
  int? _highlightedMessageId;
  bool _didJumpToTarget = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = switch (widget.initialTab) {
      'chat' => 1,
      'history' => 2,
      _ => 0,
    };
    _tabC = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabC.addListener(_onTabChanged);
    _load();
    _connectStomp();
  }

  void _onTabChanged() {
    if (!_tabC.indexIsChanging && _tabC.index == 0) {
      _loadTicket();
    }
  }

  Future<void> _loadTicket() async {
    try {
      final ticket = await TicketApi.getTicket(widget.ticketId);
      if (mounted) setState(() => _ticket = ticket);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabC.removeListener(_onTabChanged);
    _stompClient?.deactivate();
    _chatScrollC.dispose();
    super.dispose();
  }

  Future<void> _connectStomp() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;
    final wsUrl = dotenv.env['wsUrl']!;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          _stompClient!.subscribe(
            destination: '/topic/chat/${widget.ticketId}',
            callback: (frame) {
              if (frame.body != null) {
                final msg = jsonDecode(frame.body!);
                if (mounted) {
                  setState(() => _messages.add(msg));
                  _scrollToBottom();
                }
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollC.hasClients) {
        _chatScrollC.animateTo(
          _chatScrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _load() async {
    try {
      final ticket = await TicketApi.getTicket(widget.ticketId);
      final messages = await ChatApi.getMessages(widget.ticketId);
      final history = await TicketApi.getStatusHistory(widget.ticketId);
      setState(() { _ticket = ticket; _messages = messages; _history = history; _loading = false; });
      _maybeJumpToTargetMessage();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _maybeJumpToTargetMessage() {
    final target = widget.targetMessageId;
    if (target == null || _didJumpToTarget) return;
    _didJumpToTarget = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _messageKeys[target];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 400), alignment: 0.3);
        setState(() => _highlightedMessageId = target);
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) setState(() => _highlightedMessageId = null);
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_msgC.text.trim().isEmpty) return;
    try {
      await ChatApi.sendMessage(widget.ticketId, _msgC.text.trim());
      _msgC.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractError(e)), backgroundColor: Colors.red));
      }
    }
  }

  void _openPhoto(BuildContext ctx, String url, List urls) {
    final initialIndex = urls.indexOf(url);
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => _PhotoViewer(urls: urls.cast<String>(), initialIndex: initialIndex),
    ));
  }

  Future<void> _confirmPrices() async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Согласие с ценами'),
        content: const Text(
          'Подтверждая, вы соглашаетесь с указанными ценами на оказанные услуги. '
          'Действие зафиксирует ваше согласие и не может быть отменено.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Согласен')),
        ],
      ),
    );
    if (agreed != true) return;
    try {
      final updated = await TicketApi.confirmPrices(widget.ticketId);
      if (mounted) {
        setState(() => _ticket = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Согласие зафиксировано')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractError(e)), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Отменить заявку?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Да, отменить')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await TicketApi.cancelTicket(widget.ticketId);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка отменена')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_extractError(e)), backgroundColor: Colors.red));
        }
      }
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      return (e.response!.data as Map)['error']?.toString() ?? 'Ошибка';
    }
    return 'Ошибка';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Новая' => Colors.blue,
      'В работе' => Colors.orange,
      'Завершена' => Colors.green,
      'Отменена' => Colors.red,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_ticket == null) return const Scaffold(body: Center(child: Text('Заявка не найдена')));
    final t = _ticket!;

    return Scaffold(
      appBar: AppBar(
        title: Text('#${t['id']} ${t['title']}', overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabC,
          tabs: const [Tab(text: 'Детали'), Tab(text: 'Чат'), Tab(text: 'История')],
        ),
      ),
      body: TabBarView(
        controller: _tabC,
        children: [
          _buildDetails(t),
          _buildChat(),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildDetails(Map<String, dynamic> t) {
    return RefreshIndicator(
      onRefresh: _loadTicket,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(t['status']).withAlpha(25),
              borderRadius: BorderRadius.circular(12)),
            child: Text(t['status'], style: TextStyle(
              color: _statusColor(t['status']), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          _info('Категория', t['category']),
          _info('Описание', t['description']),
          _info('Заказчик', t['customerName']),
          _info('Мастер', t['masterName'] ?? '—'),
          _info('Создана', DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(t['createdAt']))),
          if (t['selectedDatetime'] != null)
            _info('Дата передачи', DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(t['selectedDatetime']))),
          if ((t['services'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Услуги', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...((t['services'] as List).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${s['serviceName']} x${s['quantity']}', style: const TextStyle(fontSize: 13))),
                  Text('${s['subtotal']} ₽', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ))),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Итого:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${t['totalPrice']} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildPricesConsent(t),
          ],
          if ((t['mediaUrls'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Фотографии', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: (t['mediaUrls'] as List).map((url) {
                  final fixedUrl = fixMediaUrl(url.toString());
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _openPhoto(context, fixedUrl,
                          (t['mediaUrls'] as List).map((u) => fixMediaUrl(u.toString())).toList()),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: fixedUrl, width: 120, height: 120, fit: BoxFit.cover),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (t['status'] == 'Новая') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Отменить заявку'),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildPricesConsent(Map<String, dynamic> t) {
    final confirmedAt = t['pricesConfirmedAt'];
    final isConfirmed = confirmedAt != null;
    final status = t['status'] as String;
    final canConfirm = !isConfirmed && status != 'Отменена';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isConfirmed ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConfirmed ? Colors.green.shade200 : Colors.amber.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: canConfirm ? _confirmPrices : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    isConfirmed ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isConfirmed ? Colors.green.shade700 : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Согласен с ценами на оказанные услуги',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isConfirmed ? Colors.green.shade900 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isConfirmed
                ? 'Подтверждено ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(confirmedAt))}'
                : 'Юридическая отметка о согласии заказчика. После подтверждения отменить нельзя.',
            style: TextStyle(
              fontSize: 11,
              color: isConfirmed ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollC,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final isMe = m['senderId'] == _ticket!['customerId'];
              final mid = m['id'] as int;
              final key = _messageKeys.putIfAbsent(mid, () => GlobalKey());
              final isHighlighted = _highlightedMessageId == mid;
              return Align(
                key: key,
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: isHighlighted
                        ? Border.all(color: Colors.amber, width: 3)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['senderName'], style: TextStyle(
                        fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
                      const SizedBox(height: 2),
                      Text(m['text'], style: TextStyle(
                        fontSize: 14, color: isMe ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(DateFormat('HH:mm').format(DateTime.parse(m['dateSent'])),
                            style: TextStyle(fontSize: 10, color: isMe ? Colors.white54 : Colors.grey)),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              m['read'] == true ? Icons.done_all : Icons.done,
                              size: 14,
                              color: m['read'] == true ? Colors.lightBlueAccent : (isMe ? Colors.white54 : Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgC,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Сообщение...', border: OutlineInputBorder(),
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _sendMessage, icon: const Icon(Icons.send)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final h = _history[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(h['status'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h['changedBy'], style: const TextStyle(fontSize: 12)),
                if (h['description'] != null)
                  Text(h['description'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: Text(
              DateFormat('dd.MM HH:mm').format(DateTime.parse(h['updatedAt'])),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _PhotoViewer({required this.urls, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pageC;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageC = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}', style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageC,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
              placeholder: (_, _) => const CircularProgressIndicator(),
              errorWidget: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
