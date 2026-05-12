import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class RealtimeReservationNotificationService {
  RealtimeReservationNotificationService._();
  static final RealtimeReservationNotificationService _instance =
      RealtimeReservationNotificationService._();
  factory RealtimeReservationNotificationService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isPrimed = false;
  String? _activeUserId;

  static const String _cachePrefix = 'reservation_signature_';

  Future<void> startForUser(String userId) async {
    if (userId.isEmpty) return;
    if (_activeUserId == userId && _subscription != null) return;

    await stop();

    _activeUserId = userId;
    _isPrimed = false;

    _subscription = _db
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(_handleSnapshot);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _isPrimed = false;
    _activeUserId = null;
  }

  Future<void> _handleSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    // Ignore the first snapshot to avoid replay notifications on app launch.
    if (!_isPrimed) {
      final prefs = await SharedPreferences.getInstance();
      for (final doc in snapshot.docs) {
        final signature = _computeSignature(doc.data());
        await prefs.setString('$_cachePrefix${doc.id}', signature);
      }
      _isPrimed = true;
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    for (final change in snapshot.docChanges) {
      final reservationId = change.doc.id;
      final data = change.doc.data();
      if (data == null) continue;

      final newSignature = _computeSignature(data);
      final cacheKey = '$_cachePrefix$reservationId';
      final oldSignature = prefs.getString(cacheKey);

      if (oldSignature == newSignature) continue;

      final status = (data['status'] ?? 'pending').toString();
      final resourceName = (data['resourceName'] ?? 'Ressource').toString();

      final message = _buildMessage(
        changeType: change.type,
        status: status,
        resourceName: resourceName,
      );

      if (message != null) {
        await _notificationService.showNotification(
          title: message.$1,
          body: message.$2,
        );
      }

      if (change.type == DocumentChangeType.removed) {
        await prefs.remove(cacheKey);
      } else {
        await prefs.setString(cacheKey, newSignature);
      }
    }
  }

  (String, String)? _buildMessage({
    required DocumentChangeType changeType,
    required String status,
    required String resourceName,
  }) {
    if (changeType == DocumentChangeType.removed) {
      return ('Reservation supprimee',
          'Une reservation a ete supprimee pour $resourceName.');
    }

    switch (status) {
      case 'approved':
        return (
          'Reservation approuvee',
          'Votre reservation pour $resourceName est approuvee.',
        );
      case 'rejected':
        return (
          'Reservation rejetee',
          'Votre reservation pour $resourceName a ete rejetee.',
        );
      case 'cancelled':
        return (
          'Reservation annulee',
          'Votre reservation pour $resourceName a ete annulee.',
        );
      case 'pending':
        return (
          'Reservation en attente',
          'Votre reservation pour $resourceName est en attente.',
        );
      default:
        return (
          'Reservation modifiee',
          'Votre reservation pour $resourceName a ete mise a jour.',
        );
    }
  }

  String _computeSignature(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    final managerComment = (data['managerComment'] ?? '').toString();
    final startAt = data['startAt'] is Timestamp
        ? (data['startAt'] as Timestamp).millisecondsSinceEpoch
        : data['startAt'].toString();
    final endAt = data['endAt'] is Timestamp
        ? (data['endAt'] as Timestamp).millisecondsSinceEpoch
        : data['endAt'].toString();

    return '$status|$managerComment|$startAt|$endAt';
  }
}
