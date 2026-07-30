import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../model/financial_model.dart';

class FinancialApiService {
  String get _baseEndpoint {
    final configured = dotenv.env['FINANCIAL_API_BASE_URL'];
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim().replaceAll(RegExp(r'/$'), '');
    }
    final chatEndpoint = dotenv.env['CHAT_API_URL'];
    if (chatEndpoint != null && chatEndpoint.trim().isNotEmpty) {
      final trimmed = chatEndpoint.trim();
      if (trimmed.endsWith('/chat')) {
        return trimmed.substring(0, trimmed.length - '/chat'.length);
      }
      return trimmed;
    }
    return 'http://10.0.2.2:8000';
  }

  Future<FinancialSummary> fetchSummary({
    required String userId,
    int horizonMonths = 12,
  }) async {
    final data = await _post('/financial/summary', {
      'user_id': userId,
      'horizon_months': horizonMonths,
    });
    return FinancialSummary.fromMap(data);
  }

  Future<FinancialTarget> upsertTarget({
    required String userId,
    required String month,
    required double monthlyBudgetRm,
    required double targetGrowthPct,
  }) async {
    final data = await _post('/financial/targets', {
      'user_id': userId,
      'month': month,
      'monthly_budget_rm': monthlyBudgetRm,
      'target_growth_pct': targetGrowthPct,
    });
    return FinancialTarget.fromMap(data);
  }

  Future<FinancialTarget> fetchTarget({
    required String userId,
    required String month,
  }) async {
    final uid = Uri.encodeQueryComponent(userId);
    final mon = Uri.encodeQueryComponent(month);
    final data = await _get('/financial/targets?user_id=$uid&month=$mon');
    return FinancialTarget.fromMap(data);
  }

  Future<DailyFinancialLog> upsertDailyLog({
    required String userId,
    required String logDate,
    required double revenueRm,
    required double expenseRm,
    String? note,
  }) async {
    final data = await _post('/financial/logs', {
      'user_id': userId,
      'log_date': logDate,
      'revenue_rm': revenueRm,
      'expense_rm': expenseRm,
      'note': note,
    });
    return DailyFinancialLog.fromMap(data);
  }

  Future<List<DailyFinancialLog>> fetchDailyLogs({
    required String userId,
    required String month,
  }) async {
    final uid = Uri.encodeQueryComponent(userId);
    final mon = Uri.encodeQueryComponent(month);
    final data = await _get('/financial/logs?user_id=$uid&month=$mon');
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => DailyFinancialLog.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return items;
  }

  Future<FinancialGrowthGraphData> fetchGrowthGraph({
    required String userId,
    required String month,
  }) async {
    final data = await _post('/financial/growth-graph', {
      'user_id': userId,
      'month': month,
    });
    return FinancialGrowthGraphData.fromMap(data);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseEndpoint$path');
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Financial API failed (${response.statusCode}): $body');
      }
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseEndpoint$path');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 30));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Financial API failed (${response.statusCode}): $body');
      }
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } finally {
      client.close(force: true);
    }
  }
}
