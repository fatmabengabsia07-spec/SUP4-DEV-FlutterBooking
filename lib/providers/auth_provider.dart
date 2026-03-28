import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {

  final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? _currentUser;
  UserRole _selectedRole = UserRole.user;

  bool _isLoading = false;
  String? _errorMessage;


  User? get currentUser => _currentUser;
  UserRole get selectedRole => _selectedRole;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  void setRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }


  Future<bool> signup(
      String name,
      String email,
      String password) async {

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {

      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final userData = {
        "name": name,
        "email": email,
        "role": "user",
        "phone": "",
        "photoPath": null,
        "birthDate": null,
        "createdAt": DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection("users")
          .doc(uid)
          .set(userData);

      _currentUser = User.fromJson(userData, uid);

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = "Erreur lors de la création du compte";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> login(
      String email,
      String password) async {

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {

      final userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final doc =
          await _firestore.collection("users").doc(uid).get();

      if (!doc.exists) {
        _errorMessage = "Utilisateur introuvable";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = doc.data()!;
      _currentUser = User.fromJson(data, uid);

      if (_currentUser!.role != _selectedRole) {
        _errorMessage =
            "Vous n'avez pas accès avec ce rôle";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = "Email ou mot de passe incorrect";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<void> checkAuthStatus() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) return;

    final doc = await _firestore
        .collection("users")
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists) {
      _currentUser =
          User.fromJson(doc.data()!, firebaseUser.uid);
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
Future<void> loadUserData() async {
  final firebaseUser = _auth.currentUser;
  if (firebaseUser == null) return;

  final doc = await _firestore
      .collection("users")
      .doc(firebaseUser.uid)
      .get();

  if (doc.exists) {
    _currentUser =
        User.fromJson(doc.data()!, firebaseUser.uid);
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