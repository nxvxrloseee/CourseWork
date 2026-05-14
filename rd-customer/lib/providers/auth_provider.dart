import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../api/auth_api.dart';
import '../api/user_api.dart';
import '../services/push_service.dart';

String _extractError(dynamic e) {
  if (e is DioException && e.response?.data is Map) {
    return (e.response!.data as Map)['error']?.toString() ?? 'Ошибка';
  }
  if (e is Exception) return e.toString().replaceAll('Exception: ', '');
  return 'Ошибка';
}

class AuthState {
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final bool isLoading;

  AuthState({this.isAuthenticated = false, this.user, this.isLoading = false});

  AuthState copyWith({bool? isAuthenticated, Map<String, dynamic>? user, bool? isLoading}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  Future<void> checkAuth() async {
    final token = await storage.read(key: 'token');
    if (token != null) {
      try {
        final user = await UserApi.getProfile();
        state = AuthState(isAuthenticated: true, user: user);
        PushService.connect();
      } catch (_) {
        await storage.delete(key: 'token');
        state = AuthState();
      }
    }
  }

  Future<void> register({
    required String surname,
    required String name,
    String? patronymic,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await AuthApi.register(
        surname: surname, name: name, patronymic: patronymic,
        email: email, password: password, confirmPassword: confirmPassword,
      );
      await storage.write(key: 'token', value: data['token']);
      final user = await UserApi.getProfile();
      state = AuthState(isAuthenticated: true, user: user);
      PushService.connect();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception(_extractError(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await AuthApi.login(email: email, password: password);
      if (data['role'] != 'CUSTOMER') {
        throw Exception('Доступ только для заказчиков');
      }
      await storage.write(key: 'token', value: data['token']);
      final user = await UserApi.getProfile();
      state = AuthState(isAuthenticated: true, user: user);
      PushService.connect();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception(_extractError(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    PushService.disconnect();
    try { await AuthApi.logout(); } catch (_) {}
    await storage.delete(key: 'token');
    state = AuthState();
  }

  void updateUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
