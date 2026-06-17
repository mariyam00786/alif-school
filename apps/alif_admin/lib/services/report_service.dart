import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/report.dart';

class ReportService {
  static Future<ReportResponse> getDailyReport({
    required DateTime date,
    String? batchId,
  }) async {
    final query = <String, String>{
      'date': _toIsoDate(date),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/daily', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load daily report: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ReportResponse.fromJson(decoded);
  }

  static Future<ReportResponse> getWeeklyReport({
    required DateTime weekStart,
    String? batchId,
  }) async {
    final normalized = _mondayOfWeek(weekStart);
    final query = <String, String>{
      'week_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/weekly', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load weekly report: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ReportResponse.fromJson(decoded);
  }

  static Future<ReportResponse> getMonthlyReport({
    required DateTime monthStart,
    String? batchId,
  }) async {
    final normalized = DateTime(monthStart.year, monthStart.month, 1);
    final query = <String, String>{
      'month_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/monthly', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load monthly report: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ReportResponse.fromJson(decoded);
  }

  static Future<String> exportDailyCsv({
    required DateTime date,
    String? batchId,
  }) async {
    final query = <String, String>{
      'date': _toIsoDate(date),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/daily/export', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export daily report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> exportWeeklyCsv({
    required DateTime weekStart,
    String? batchId,
  }) async {
    final normalized = _mondayOfWeek(weekStart);
    final query = <String, String>{
      'week_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/weekly/export', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export weekly report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> exportMonthlyCsv({
    required DateTime monthStart,
    String? batchId,
  }) async {
    final normalized = DateTime(monthStart.year, monthStart.month, 1);
    final query = <String, String>{
      'month_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/monthly/export', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export monthly report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> exportDailyExcel({
    required DateTime date,
    String? batchId,
  }) async {
    final query = <String, String>{
      'date': _toIsoDate(date),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/daily/export/excel', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export daily Excel report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> exportWeeklyExcel({
    required DateTime weekStart,
    String? batchId,
  }) async {
    final normalized = _mondayOfWeek(weekStart);
    final query = <String, String>{
      'week_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/weekly/export/excel', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export weekly Excel report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> exportMonthlyExcel({
    required DateTime monthStart,
    String? batchId,
  }) async {
    final normalized = DateTime(monthStart.year, monthStart.month, 1);
    final query = <String, String>{
      'month_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/monthly/export/excel', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export monthly Excel report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> getDailyPrintHtml({
    required DateTime date,
    String? batchId,
  }) async {
    final query = <String, String>{
      'date': _toIsoDate(date),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/daily/print', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch daily print report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> getWeeklyPrintHtml({
    required DateTime weekStart,
    String? batchId,
  }) async {
    final normalized = _mondayOfWeek(weekStart);
    final query = <String, String>{
      'week_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/weekly/print', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weekly print report: ${response.body}');
    }

    return response.body;
  }

  static Future<String> getMonthlyPrintHtml({
    required DateTime monthStart,
    String? batchId,
  }) async {
    final normalized = DateTime(monthStart.year, monthStart.month, 1);
    final query = <String, String>{
      'month_start': _toIsoDate(normalized),
      if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
    };

    final response = await http.get(
      AppConfig.apiUri('/reports/monthly/print', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch monthly print report: ${response.body}');
    }

    return response.body;
  }

  static String _toIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _mondayOfWeek(DateTime date) {
    final day = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: day - 1));
  }
}
