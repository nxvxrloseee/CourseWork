import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surnameC = TextEditingController();
  final _nameC = TextEditingController();
  final _patronymicC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passC.text != _confirmC.text) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).register(
        surname: _surnameC.text.trim(),
        name: _nameC.text.trim(),
        patronymic: _patronymicC.text.trim().isEmpty ? null : _patronymicC.text.trim(),
        email: _emailC.text.trim(),
        password: _passC.text,
        confirmPassword: _confirmC.text,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
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
                  decoration: const InputDecoration(labelText: 'Отчество (необязательно)', border: OutlineInputBorder(), counterText: ''),
                  validator: (v) => v != null && v.trim().isNotEmpty && v.trim().length > 50 ? 'Максимум 50 символов' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailC,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), counterText: ''),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().length < 5) return 'Минимум 5 символов';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return 'Введите корректный email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passC,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder(), counterText: ''),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Минимум 6 символов' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmC,
                  decoration: const InputDecoration(labelText: 'Подтвердите пароль', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Обязательно';
                    if (v != _passC.text) return 'Пароли не совпадают';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Зарегистрироваться'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Уже есть аккаунт? Войти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
