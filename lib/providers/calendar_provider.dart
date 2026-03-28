import 'package:flutter/material.dart';

class CalendarProvider with ChangeNotifier {

  DateTime selectedDay = DateTime.now();

  void selectDay(DateTime day) {
    selectedDay = day;
    notifyListeners();
  }
}