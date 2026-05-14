import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../api/user_api.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();
  final _surnameC = TextEditingController();
  final _nameC = TextEditingController();
  final _patronymicC = TextEditingController();
  final _curPassC = TextEditingController();
  final _newPassC = TextEditingController();
  final _confirmPassC = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _surnameC.text = user['surname'] ?? '';
      _nameC.text = user['name'] ?? '';
      _patronymicC.text = user['patronymic'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    try {
      final data = await UserApi.updateProfile(
        surname: _surnameC.text.trim(),
        name: _nameC.text.trim(),
        patronymic: _patronymicC.text.trim(),
      );
      ref.read(authProvider.notifier).updateUser(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractError(e)), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passKey.currentState!.validate()) return;
    try {
      await UserApi.changePassword(
        currentPassword: _curPassC.text,
        newPassword: _newPassC.text,
        confirmPassword: _confirmPassC.text,
      );
      _curPassC.clear(); _newPassC.clear(); _confirmPassC.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль изменён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractError(e)), backgroundColor: Colors.red));
      }
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      return (e.response!.data as Map)['error']?.toString() ?? 'Ошибка';
    }
    return 'Ошибка';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Личные данные', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Form(
              key: _profileKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _surnameC,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: 'Фамилия', border: OutlineInputBorder(), counterText: ''),
                    validator: (v) => v == null || v.trim().length < 2 ? 'От 2 до 50 символов' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameC,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder(), counterText: ''),
                    validator: (v) => v == null || v.trim().length < 2 ? 'От 2 до 50 символов' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _patronymicC,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: 'Отчество', border: OutlineInputBorder(), counterText: ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _saveProfile, child: const Text('Сохранить'))),
            const SizedBox(height: 32),
            const Text('Смена пароля', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Form(
              key: _passKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _curPassC,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Текущий пароль', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Обязательно' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPassC,
                    obscureText: true,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Новый пароль', border: OutlineInputBorder(), counterText: ''),
                    validator: (v) => v == null || v.length < 6 ? 'Минимум 6 символов' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassC,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Подтвердите пароль', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Обязательно';
                      if (v != _newPassC.text) return 'Пароли не совпадают';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _changePassword, child: const Text('Сменить пароль'))),
          ],
        ),
      ),
    );
  }
}
