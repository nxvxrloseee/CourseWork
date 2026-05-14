import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../api/ticket_api.dart';
import '../api/category_api.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  int? _categoryId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<dynamic> _categories = [];
  final List<XFile> _photos = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    CategoryApi.getCategories().then((c) => setState(() => _categories = c));
  }

  static const int _maxFileBytes = 10 * 1024 * 1024;

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    final accepted = <XFile>[];
    final rejected = <String>[];
    for (final img in images) {
      final size = await File(img.path).length();
      if (size > _maxFileBytes) {
        rejected.add(img.name);
      } else {
        accepted.add(img);
      }
    }
    if (!mounted) return;
    setState(() => _photos.addAll(accepted));
    if (rejected.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Файл слишком большой (макс 10 МБ): ${rejected.join(", ")}',
        ),
      ));
    }
  }

  static const int _businessOpen = 8;
  static const int _businessClose = 22;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: _businessOpen.clamp(_businessOpen, _businessClose - 1), minute: 0),
      );
      if (time == null) return;
      if (time.hour < _businessOpen || time.hour >= _businessClose) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Приём устройств с $_businessOpen:00 до $_businessClose:00'),
        ));
        return;
      }
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (dt.isBefore(DateTime.now())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Дата передачи не может быть в прошлом'),
        ));
        return;
      }
      setState(() { _selectedDate = date; _selectedTime = time; });
    }
  }

  String? _getDatetime() {
    if (_selectedDate == null) return null;
    final dt = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime?.hour ?? 0, _selectedTime?.minute ?? 0,
    );
    return dt.toIso8601String();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _loading = true);
    try {
      await TicketApi.createTicket(
        categoryId: _categoryId!,
        title: _titleC.text.trim(),
        description: _descC.text.trim(),
        selectedDatetime: _getDatetime(),
        filePaths: _photos.map((p) => p.path).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка создана!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Ошибка';
        if (e is DioException) {
          if (e.response?.statusCode == 413) {
            msg = 'Файл слишком большой. Максимальный размер — 10 МБ';
          } else if (e.response?.data is Map) {
            msg = (e.response!.data as Map)['error']?.toString() ?? msg;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новая заявка')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
                items: _categories.map((c) =>
                  DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Выберите категорию' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleC,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder(), counterText: ''),
                validator: (v) {
                  if (v == null || v.trim().length < 5) return 'От 5 до 100 символов';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descC,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Описание неисправности', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().length < 10) return 'От 10 до 1000 символов';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_selectedDate != null
                  ? 'Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime(
                      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
                      _selectedTime?.hour ?? 0, _selectedTime?.minute ?? 0))}'
                  : 'Выбрать дату и время передачи'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Приём устройств: с 8:00 до 22:00',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.camera_alt),
                label: Text('Фото (${_photos.length})'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Макс. размер одного файла — 10 МБ',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_photos[i].path), width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _photos.removeAt(i)),
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Создать заявку'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
