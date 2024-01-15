// attendance_data.dart

import 'package:flutter/material.dart';

class AttendanceData extends ChangeNotifier {
  List<Map<String, dynamic>> _attendanceRecords = [];

  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;

  void updateAttendanceRecords(List<Map<String, dynamic>> records) {
    _attendanceRecords = records;
    notifyListeners();
  }
}
