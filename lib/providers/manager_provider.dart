import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/manager_service.dart';

class ManagerProvider with ChangeNotifier {
  final ManagerService _service = ManagerService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<User>> get stream {
    return _service.streamManagers();
  }

  Future<bool> addManager({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _service.createManager(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateManager(User manager) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _service.updateManager(manager);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> demoteManagerToUser(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _service.demoteManagerToUser(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<User?> getManagerById(String managerId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final manager = await _service.getManagerById(managerId);

      _setLoading(false);
      return manager;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}