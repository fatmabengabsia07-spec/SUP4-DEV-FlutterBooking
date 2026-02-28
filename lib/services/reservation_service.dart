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

  Stream<List<Reservation>> streamReservationsForResourceDay({
    required String resourceId,
    required DateTime day,
  }) {

    final startDay = DateTime(day.year, day.month, day.day);
    final endDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

    return _db
        .collection('reservations')
        .where('resourceId', isEqualTo: resourceId)
        .where('startAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDay))
        .where('startAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDay))
        .orderBy('startAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                Reservation.fromFirestore(d.id, d.data()))
            .toList());
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
          .where('status',
              whereIn: ['pending', 'approved'])
          .where('startAt',
              isLessThan: Timestamp.fromDate(endAt))
          .get();

      final hasConflict = conflictQuery.docs.any((doc) {
        final data = doc.data();
        final existingEnd =
            (data['endAt'] as Timestamp).toDate();

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
        "status":
            requiresApproval ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });
    });
  }
}