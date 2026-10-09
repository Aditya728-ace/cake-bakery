import 'package:flutter/material.dart';
import 'api_client.dart';
import 'nav.dart';

class AuthState extends ChangeNotifier {
  late final ApiClient api = ApiClient(onSessionExpired: _expired);
  bool ready = false;
  bool loggedIn = false;

  Future<void> init() async {
    await api.load();
    loggedIn = api.hasSession;
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final j = await api.post('/api/auth/login', {'email': email.trim(), 'password': password}, false);
    await api.saveTokens(j as Map<String, dynamic>);
    loggedIn = true;
    notifyListeners();
  }

  Future<void> register(String email, String password, String bakeryName, String inviteCode) async {
    final j = await api.post('/api/auth/register', {
      'email': email.trim(),
      'password': password,
      'bakery_name': bakeryName.trim(),
      if (inviteCode.trim().isNotEmpty) 'invite_code': inviteCode.trim(),
    }, false);
    await api.saveTokens(j as Map<String, dynamic>);
    loggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.clear();
    _expired();
  }

  void _expired() {
    loggedIn = false;
    navigatorKey.currentState?.popUntil((r) => r.isFirst);
    notifyListeners();
  }
}
