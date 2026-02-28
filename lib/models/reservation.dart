import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus { pending, approved, rejected, cancelled }

class Reservation {
  final String id;
  final String resourceId;
  final String userId;
  final DateTime startAt;
  final DateTime endAt;
  final ReservationStatus status;

  Reservation({
    required this.id,
    required this.resourceId,
    required this.userId,
    required this.startAt,
    required this.endAt,
    required this.status,
  });

  factory Reservation.fromFirestore(String id, Map<String, dynamic> data) {
    return Reservation(
      id: id,
      resourceId: data['resourceId'] ?? '',
      userId: data['userId'] ?? '',
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      status: _parseStatus(data['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'userId': userId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static ReservationStatus _parseStatus(String? s) {
    switch (s) {
      case 'approved':
        return ReservationStatus.approved;
      case 'rejected':
        return ReservationStatus.rejected;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.pending;
    }
  }
  Reservation copyWith({
  ReservationStatus? status,
}) {
  return Reservation(
    id: id,
    resourceId: resourceId,
    userId: userId,
    startAt: startAt,
    endAt: endAt,
    status: status ?? this.status,
  );
}
}
