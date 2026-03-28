import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

class ReservationConflictException implements Exception {
  final String message;
  ReservationConflictException(this.message);

  @override
  String toString() => message;
}

class ReservationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> getResourceName(String resourceId) async {
    final resourceDoc = await _db.collection('resources').doc(resourceId).get();
    return resourceDoc.data()?['name'] ?? 'Ressource inconnue';
  }

  Future<String> getUserName(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    return userDoc.data()?['name'] ?? 'Utilisateur inconnu';
  }

  Stream<List<Reservation>> streamReservationsForResourceDay({
    required String resourceId,
    required DateTime day,
  }) {
    final startDay = DateTime(day.year, day.month, day.day);
    final endDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

    return _db
        .collection('reservations')
        .where('resourceId', isEqualTo: resourceId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDay))
        .where('startAt', isLessThanOrEqualTo: Timestamp.fromDate(endDay))
        .orderBy('startAt')
        .snapshots()
        .asyncMap((snap) async {
          final reservations = await Future.wait(snap.docs.map((d) async {
            final reservation = Reservation.fromFirestore(d.id, d.data());
            final resourceName = await getResourceName(reservation.resourceId);
            final userName = await getUserName(reservation.userId);
            return reservation.copyWith(
              resourceName: resourceName,
              userName: userName,
            );
          }).toList());

          return reservations;
        });
  }

  Future<void> createReservation({
    required String resourceId,
    required String userId,
    required DateTime startAt,
    required DateTime endAt,
    required bool requiresApproval,
  }) async {
    final reservationsRef = _db.collection('reservations');

    await _db.runTransaction((tx) async {
      final conflictQuery = await reservationsRef
          .where('resourceId', isEqualTo: resourceId)
          .where('status', whereIn: ['pending', 'approved'])
          .where('startAt', isLessThan: Timestamp.fromDate(endAt))
          .get();

      final hasConflict = conflictQuery.docs.any((doc) {
        final data = doc.data();
        final existingEnd = (data['endAt'] as Timestamp).toDate();
        return existingEnd.isAfter(startAt);
      });

      if (hasConflict) {
        throw ReservationConflictException(
          "Ce créneau est déjà réservé.",
        );
      }

      final newDoc = reservationsRef.doc();

      tx.set(newDoc, {
        "resourceId": resourceId,
        "userId": userId,
        "startAt": Timestamp.fromDate(startAt),
        "endAt": Timestamp.fromDate(endAt),
        "status": requiresApproval ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Reservation>> streamUserReservations(String userId) {
    return _db
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final reservations = await Future.wait(snap.docs.map((d) async {
            final reservation = Reservation.fromFirestore(d.id, d.data());
            final resourceName = await getResourceName(reservation.resourceId);
            final userName = await getUserName(reservation.userId);
            return reservation.copyWith(
              resourceName: resourceName,
              userName: userName,
            );
          }).toList());
          return reservations;
        });
  }

  Future<void> deleteReservation(String id) async {
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(id)
        .delete();
  }

  Future<void> updateReservationStatus(String id, String status) async {
    await _db.collection('reservations').doc(id).update({
      "status": status,
    });
  }

  Future<void> updateReservation({
    required String id,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final reservationsRef = _db.collection('reservations');

    await _db.runTransaction((tx) async {
      final docRef = reservationsRef.doc(id);

      final doc = await tx.get(docRef);
      final resourceId = doc['resourceId'];

      final conflictQuery = await reservationsRef
          .where('resourceId', isEqualTo: resourceId)
          .where('status', whereIn: ['pending', 'approved'])
          .where('startAt', isLessThan: Timestamp.fromDate(endAt))
          .get();

      final hasConflict = conflictQuery.docs.any((d) {
        if (d.id == id) return false;
        final existingEnd = (d['endAt'] as Timestamp).toDate();
        return existingEnd.isAfter(startAt);
      });

      if (hasConflict) {
        throw Exception("Créneau déjà réservé");
      }

      tx.update(docRef, {
        "startAt": Timestamp.fromDate(startAt),
        "endAt": Timestamp.fromDate(endAt),
      });
    });
  }

  Stream<List<Reservation>> streamPendingReservations() {
    return _db
        .collection('reservations')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final reservations = await Future.wait(snap.docs.map((d) async {
            final reservation = Reservation.fromFirestore(d.id, d.data());
            final resourceName = await getResourceName(reservation.resourceId);
            final userName = await getUserName(reservation.userId);
            return reservation.copyWith(
              resourceName: resourceName,
              userName: userName,
            );
          }).toList());
          return reservations;
        });
  }

  Stream<List<Reservation>> streamAllReservations() {
    return _db
        .collection('reservations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final reservations = await Future.wait(snap.docs.map((d) async {
            final reservation = Reservation.fromFirestore(d.id, d.data());
            final resourceName = await getResourceName(reservation.resourceId);
            final userName = await getUserName(reservation.userId);
            return reservation.copyWith(
              resourceName: resourceName,
              userName: userName,
            );
          }).toList());
          return reservations;
        });
  }

  Future<void> approveReservation({
    required String reservationId,
    required String managerId,
    String? comment,
  }) async {
    await _db.collection('reservations').doc(reservationId).update({
      "status": "approved",
      "managerId": managerId,
      "managerComment": comment ?? "",
    });
  }

  Future<void> rejectReservation({
    required String reservationId,
    required String managerId,
    String? comment,
  }) async {
    await _db.collection('reservations').doc(reservationId).update({
      "status": "rejected",
      "managerId": managerId,
      "managerComment": comment ?? "",
    });
  }

  Stream<List<Reservation>> streamReservationsReviewedByManager(String managerId) {
    return _db
        .collection('reservations')
        .where('managerId', isEqualTo: managerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final reservations = await Future.wait(snap.docs.map((d) async {
            final reservation = Reservation.fromFirestore(d.id, d.data());
            final resourceName = await getResourceName(reservation.resourceId);
            final userName = await getUserName(reservation.userId);
            return reservation.copyWith(
              resourceName: resourceName,
              userName: userName,
            );
          }).toList());
          return reservations;
        });
  }
}