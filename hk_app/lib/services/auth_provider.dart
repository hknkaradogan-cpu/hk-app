import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isSupervisor => _user?.role == 'supervisor';

  final _auth = AuthService();

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _auth.signIn(email, password);
      if (_user == null) {
        _error = 'Giriş başarısız. Kullanıcı bulunamadı.';
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
    return _user != null;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _user = await _auth.currentUserProfile();
    notifyListeners();
  }
}
