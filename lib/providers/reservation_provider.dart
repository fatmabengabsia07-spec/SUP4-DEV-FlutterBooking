import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _service = ReservationService();

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
  
}