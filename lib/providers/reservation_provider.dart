import 'package:flutter/material.dart';
import 'package:projet/models/reservation.dart';
import '../services/reservation_service.dart';
import '../services/notification_service.dart';  // Importez le service de notification

class ReservationProvider with ChangeNotifier {
  final ReservationService _service = ReservationService();
  final NotificationService _notificationService = NotificationService();  // Initialisation du service de notification

  DateTime selectedDay = DateTime.now();
  int? selectedHour;
  bool loading = false;
  String? error;

  void setDay(DateTime day) {
    selectedDay = day;
    selectedHour = null;
    error = null;
    notifyListeners();
  }

  void setHour(int hour) {
    selectedHour = hour;
    error = null;
    notifyListeners();
  }

  Stream<List<Reservation>> reservationsForDay(String resourceId) {
    return _service.streamReservationsForResourceDay(
      resourceId: resourceId,
      day: selectedDay,
    );
  }

  Future<bool> confirmReservation({
    required String resourceId,
    required String userId,
    required bool requiresApproval,
    required int durationMinutes,
  }) async {
    if (selectedHour == null) {
      error = "Choisissez une heure";
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final startAt = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        selectedHour!,
        0,
      );
      final endAt = startAt.add(Duration(minutes: durationMinutes));

      await _service.createReservation(
        resourceId: resourceId,
        userId: userId,
        startAt: startAt,
        endAt: endAt,
        requiresApproval: requiresApproval,
      );

      await _notificationService.showNotification(
        id: 0,
        title: 'Réservation en cours de traitement.',
        body: 'Votre réservation pour la ressource est en cours de traitement.',
      );

      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      loading = false;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Stream<List<Reservation>> userReservations(String userId) {
    return _service.streamUserReservations(userId);
  }

  Future<void> delete(String id) async {
    await _service.deleteReservation(id);
  }

  Future<void> cancel(String id) async {
    await _service.updateReservationStatus(id, "cancelled");

    await _notificationService.showNotification(
      id: 1,
      title: 'Réservation annulée',
      body: 'Votre réservation a été annulée.',
    );
  }

  Future<bool> updateReservation({
    required String id,
    required int durationMinutes,
  }) async {
    if (selectedHour == null) {
      error = "Choisissez une heure";
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final startAt = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        selectedHour!,
      );

      final endAt = startAt.add(Duration(minutes: durationMinutes));

      await _service.updateReservation(
        id: id,
        startAt: startAt,
        endAt: endAt,
      );

      await _notificationService.showNotification(
        id: 2,
        title: 'Réservation modifiée',
        body: 'Votre réservation a été modifiée avec succès.',
      );

      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      loading = false;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Stream<List<Reservation>> pendingReservations() {
    return _service.streamPendingReservations();
  }

  Stream<List<Reservation>> allReservations() {
    return _service.streamAllReservations();
  }

  Future<bool> approve({
    required String reservationId,
    required String managerId,
    String? comment,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _service.approveReservation(
        reservationId: reservationId,
        managerId: managerId,
        comment: comment,
      );

      await _notificationService.showNotification(
        id: 3,
        title: 'Réservation approuvée',
        body: 'La réservation a été approuvée .',
      );

      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      loading = false;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> reject({
    required String reservationId,
    required String managerId,
    String? comment,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _service.rejectReservation(
        reservationId: reservationId,
        managerId: managerId,
        comment: comment,
      );

      await _notificationService.showNotification(
        id: 4,
        title: 'Réservation rejetée',
        body: 'La réservation a été rejetée .',
      );

      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      loading = false;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Stream<List<Reservation>> reviewedByManager(String managerId) {
    return _service.streamReservationsReviewedByManager(managerId);
  }
}