import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus { pending, approved, rejected, cancelled }

class Reservation {
  final String id;
  final String resourceId;
  final String userId;
  final DateTime startAt;
  final DateTime endAt;
  final ReservationStatus status;

  final String? managerId;
  final String? managerComment;
  final DateTime? createdAt;

  final String resourceName; 
  final String userName; 

  Reservation({
    required this.id,
    required this.resourceId,
    required this.userId,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.managerId,
    this.managerComment,
    this.createdAt,
    required this.resourceName,
    required this.userName, 
  });

  factory Reservation.fromFirestore(String id, Map<String, dynamic> data) {
    return Reservation(
      id: id,
      resourceId: data['resourceId'] ?? '',
      userId: data['userId'] ?? '',
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      status: _parseStatus(data['status']),
      managerId: data['managerId'],
      managerComment: data['managerComment'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      resourceName: data['resourceName'] ?? '', 
      userName: data['userName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'userId': userId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status.name,
      'managerId': managerId,
      'managerComment': managerComment,
      'createdAt': FieldValue.serverTimestamp(),
      'resourceName': resourceName, 
      'userName': userName, 
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
    String? managerId,
    String? managerComment,
    DateTime? createdAt,
    String? resourceName, 
    String? userName, 
  }) {
    return Reservation(
      id: id,
      resourceId: resourceId,
      userId: userId,
      startAt: startAt,
      endAt: endAt,
      status: status ?? this.status,
      managerId: managerId ?? this.managerId,
      managerComment: managerComment ?? this.managerComment,
      createdAt: createdAt ?? this.createdAt,
      resourceName: resourceName ?? this.resourceName,
      userName: userName ?? this.userName, 
    );
  }
}