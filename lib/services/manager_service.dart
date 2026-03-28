import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import '../models/user.dart';

class ManagerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<User>> streamManagers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'manager')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => User.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> createManager({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      final normalizedEmail = email.trim().toLowerCase();

      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryAppManager',
        options: Firebase.app().options,
      );

      final secondaryAuth =
          firebase_auth.FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final uid = credential.user!.uid;

      await _db.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': normalizedEmail,
        'role': 'manager',
        'phone': phone?.trim() ?? '',
        'photoPath': null,
        'birthDate': null,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await secondaryAuth.signOut();
      await secondaryApp.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (secondaryApp != null) {
        await firebase_auth.FirebaseAuth.instanceFor(app: secondaryApp).signOut();
        await secondaryApp.delete();
      }

      if (e.code == 'email-already-in-use') {
        throw Exception("Cet email existe déjà");
      } else if (e.code == 'weak-password') {
        throw Exception("Mot de passe trop faible");
      } else if (e.code == 'invalid-email') {
        throw Exception("Email invalide");
      } else {
        throw Exception(e.message ?? "Erreur lors de la création du manager");
      }
    } catch (e) {
      if (secondaryApp != null) {
        try {
          await firebase_auth.FirebaseAuth.instanceFor(app: secondaryApp).signOut();
          await secondaryApp.delete();
        } catch (_) {}
      }
      throw Exception("Erreur lors de la création du manager");
    }
  }

  Future<void> updateManager(User manager) async {
    if (manager.role != UserRole.manager) {
      throw Exception("Cet utilisateur n'est pas un manager");
    }

    await _db.collection('users').doc(manager.id).update({
      'name': manager.name.trim(),
      'email': manager.email.trim().toLowerCase(),
      'phone': manager.phone ?? '',
      'photoPath': manager.photoPath,
      'birthDate': manager.birthDate?.toIso8601String(),
    });
  }

  Future<void> demoteManagerToUser(String userId) async {
    await _db.collection('users').doc(userId).update({
      'role': 'user',
    });
  }

  Future<User?> getManagerById(String managerId) async {
    final doc = await _db.collection('users').doc(managerId).get();

    if (!doc.exists) return null;

    final user = User.fromJson(doc.data()!, doc.id);

    if (user.role != UserRole.manager) return null;

    return user;
  }
}