import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/validation_service.dart';
import '../services/auth_error_handler.dart';
import '../services/rate_limit_service.dart';

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  UserRole _selectedRole = UserRole.user;

  bool _isLoading = false;
  String? _errorMessage;

  bool _isEmailVerified = false;
  int? _loginLockoutTimeRemaining;

  User? get currentUser => _currentUser;
  UserRole get selectedRole => _selectedRole;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmailVerified => _isEmailVerified;
  int? get loginLockoutTimeRemaining => _loginLockoutTimeRemaining;

  void setRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  
  Future<bool> signup(String name, String email, String password) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. VALIDATION CÔTÉ CLIENT AVANT ENVOI
      final validationError = ValidationService.validateSignupForm(
        name: name,
        email: email,
        password: password,
      );

      if (validationError != null) {
        _errorMessage = validationError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. RATE LIMITING - Vérifier si email peut s'inscrire
      if (!RateLimitService.canAttemptSignup(email)) {
        _errorMessage = "Trop de tentatives d'inscription. Réessayez plus tard";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final sanitizedName = ValidationService.sanitizeInput(name);
      final sanitizedEmail = email.toLowerCase().trim();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _auth.currentUser?.sendEmailVerification();

      final userData = {
        "name": sanitizedName,
        "email": sanitizedEmail,
        "role": "user",
        "phone": "",
        "photoPath": null,
        "birthDate": null,
        "createdAt": DateTime.now().toIso8601String(),
        "emailVerified": false, 
        "lastPasswordChange":
            DateTime.now().toIso8601String(), 
      };

      await _firestore.collection("users").doc(uid).set(userData);

      RateLimitService.clearSignupAttempts(sanitizedEmail);

      _currentUser = User.fromJson(userData, uid);
      _isEmailVerified = false;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      
      RateLimitService.recordFailedSignupAttempt(email);

      _errorMessage = AuthErrorHandler.handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    _isLoading = true;
    _loginLockoutTimeRemaining = null;
    notifyListeners();

    try {
      final validationError = ValidationService.validateLoginForm(
        email: email,
        password: password,
      );

      if (validationError != null) {
        _errorMessage = validationError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!RateLimitService.canAttemptLogin(email)) {
        _loginLockoutTimeRemaining =
            RateLimitService.getLoginLockoutTimeRemaining(email);
        _errorMessage =
            "Trop de tentatives. Compte verrouillé pour ${_loginLockoutTimeRemaining} secondes";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final sanitizedEmail = email.toLowerCase().trim();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final firebaseUser = userCredential.user;

      _isEmailVerified = firebaseUser?.emailVerified ?? false;

      final doc = await _firestore.collection("users").doc(uid).get();

      if (!doc.exists) {
      
        final userData = {
          "name": sanitizedEmail,
          "email": sanitizedEmail,
          "role": "user",
          "phone": "",
          "photoPath": null,
          "birthDate": null,
          "createdAt": DateTime.now().toIso8601String(),
          "emailVerified": _isEmailVerified,
          "lastPasswordChange": DateTime.now().toIso8601String(),
        };

        await _firestore.collection("users").doc(uid).set(userData);
        _currentUser = User.fromJson(userData, uid);
      } else {
        final data = doc.data()!;
        _currentUser = User.fromJson(data, uid);
      }

      if (_currentUser!.role != _selectedRole) {
        // Enregistrer la tentative échouée
        RateLimitService.recordFailedLoginAttempt(sanitizedEmail);

        _errorMessage = "Email ou mot de passe incorrect";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      RateLimitService.clearLoginAttempts(sanitizedEmail);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
     
      RateLimitService.recordFailedLoginAttempt(email);

      _errorMessage = AuthErrorHandler.handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) return;

    final doc =
        await _firestore.collection("users").doc(firebaseUser.uid).get();

    if (doc.exists) {
      _currentUser = User.fromJson(doc.data()!, firebaseUser.uid);
      notifyListeners();
    }
  }

  Future<void> updateUser(User updatedUser) async {
    await _firestore
        .collection("users")
        .doc(updatedUser.id)
        .update(updatedUser.toJson());

    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> isEmailVerifiedByUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    _isEmailVerified = user.emailVerified;
    notifyListeners();

    return _isEmailVerified;
  }

  Future<bool> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = "Aucun utilisateur connecté";
        notifyListeners();
        return false;
      }

      await user.sendEmailVerification();
      _errorMessage = "Email de vérification renvoyé";
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Erreur lors de l'envoi de l'email";
      notifyListeners();
      return false;
    }
  }

  int getPasswordStrength(String password) {
    return ValidationService.getPasswordStrength(password);
  }

  List<String> getPasswordRequirements() {
    return ValidationService.getPasswordRequirements();
  }

  Future<void> loadUserData() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final doc =
        await _firestore.collection("users").doc(firebaseUser.uid).get();

    if (doc.exists) {
      _currentUser = User.fromJson(doc.data()!, firebaseUser.uid);
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    DateTime? birthDate,
    String? photoPath,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uid = _auth.currentUser!.uid;

      await _firestore.collection("users").doc(uid).update({
        "name": name,
        "phone": phone,
        "birthDate": birthDate?.toIso8601String(),
        "photoPath": photoPath,
      });

      await loadUserData();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = "Erreur mise à jour profil";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
