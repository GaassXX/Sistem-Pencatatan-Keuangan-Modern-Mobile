import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// MyHttpOverrides didefinisikan di lib/main.dart dan hanya aktif di kDebugMode.
// Tidak perlu redefinisi di sini.

class ApiService {
  // URL backend. Untuk perangkat fisik pakai: adb reverse tcp:8000 tcp:8000
  // lalu tetap gunakan 127.0.0.1. Untuk emulator ganti ke 10.0.2.2:8000.
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static String? token;

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'account_type': 'independent',
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      token = body['data']['token'];
      return body['data'];
    }

    if (body['message'] != null) {
      throw Exception(body['message']);
    }

    throw Exception('Registrasi gagal');
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      token = body['data']['token'];
      return body;
    }

    throw Exception(
      body['message'] ?? 'Login gagal',
    );
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Gagal mengambil profile',
    );
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'email': email,
    };
    if (password != null && password.trim().isNotEmpty) {
      payload['password'] = password.trim();
    }

    final response = await http.put(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    if (body['errors'] != null && body['errors'] is Map) {
      final errors = (body['errors'] as Map).values.map((e) => (e as List).first).join('\n');
      throw Exception(errors);
    }

    throw Exception(body['message'] ?? 'Gagal memperbarui profil');
  }

  static String getFullAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return '';
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return avatarUrl;
    }
    final host = baseUrl.replaceAll('/api', '');
    return '$host/storage/$avatarUrl';
  }

  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/me/avatar'),
    );

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath('avatar', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    if (body['errors'] != null && body['errors'] is Map) {
      final errors = (body['errors'] as Map).values.map((e) => (e as List).first).join('\n');
      throw Exception(errors);
    }

    throw Exception(body['message'] ?? 'Gagal mengunggah foto profil');
  }

  static Future<Map<String, dynamic>> deleteAvatar() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/me/avatar'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(body['message'] ?? 'Gagal menghapus foto profil');
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/stats'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Gagal mengambil dashboard',
    );
  }

  static Future<Map<String, dynamic>> getDashboardChart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/chart'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Gagal mengambil chart',
    );
  }

  // =====================================================
  // TRANSACTIONS CRUD
  // =====================================================

  static Future<List<dynamic>> getTransactionsFiltered({
    String? type,
    String? source,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (source != null) queryParams['source'] = source;
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;

    final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? [];
    }

    throw Exception(
      body['message'] ?? 'Gagal mengambil transaksi filter',
    );
  }
  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? [];
    }

    throw Exception(
      body['message'] ?? 'Gagal mengambil transaksi',
    );
  }

  static Future<Map<String, dynamic>> getTransactionDetail(dynamic id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'];
    }

    throw Exception(
      body['message'] ?? 'Gagal mengambil detail transaksi',
    );
  }

  static Future<Map<String, dynamic>> createTransaction({
    required String type,
    required double amount,
    required String description,
    required int categoryId,
    String? source,
    int? walletId,
    String? date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'amount': amount,
        'description': description,
        'category_id': categoryId,
        if (source != null) 'source': source,
        if (walletId != null) 'wallet_id': walletId,
        if (date != null) 'date': date,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Gagal menyimpan transaksi',
    );
  }

  static Future<Map<String, dynamic>> updateTransaction(
    dynamic id, {
    required String type,
    required double amount,
    required String description,
    required int categoryId,
    String? source,
    int? walletId,
    String? date,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'amount': amount,
        'description': description,
        'category_id': categoryId,
        if (source != null) 'source': source,
        if (walletId != null) 'wallet_id': walletId,
        if (date != null) 'date': date,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Gagal memperbarui transaksi',
    );
  }

  static Future<void> deleteTransaction(dynamic id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return;
    }

    throw Exception(
      body['message'] ?? 'Gagal menghapus transaksi',
    );
  }

  // =====================================================
  // CATEGORIES CRUD
  // =====================================================

  static Future<List<dynamic>> getCategories(String type) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories?type=$type'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? [];
    }

    throw Exception(
      body['message'] ?? 'Gagal mengambil kategori',
    );
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    required String type,
    String? icon,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'type': type,
        if (icon != null) 'icon': icon,
      }),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Gagal membuat kategori',
    );
  }

  static Future<Map<String, dynamic>> updateCategory(
    int id, {
    required String name,
    required String type,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'type': type,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Gagal memperbarui kategori',
    );
  }

  static Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return;
    }

    throw Exception(
      body['message'] ?? 'Gagal menghapus kategori',
    );
  }

  // =====================================================
  // BUDGETS (ANGGARAN BULANAN)
  // =====================================================

  static Future<Map<String, dynamic>> getBudgets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/budgets'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? {};
    }

    throw Exception(body['message'] ?? 'Gagal mengambil data anggaran');
  }

  static Future<Map<String, dynamic>> setBudget({
    required int categoryId,
    required double limitAmount,
    String period = 'monthly',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budgets'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'category_id': categoryId,
        'limit_amount': limitAmount,
        'period': period,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return body['data'] ?? {};
    }

    throw Exception(body['message'] ?? 'Gagal menyimpan anggaran');
  }

  static Future<void> deleteBudget(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/budgets/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Gagal menghapus anggaran');
  }

  // =====================================================
  // SAVINGS (TABUNGAN IMPIAN)
  // =====================================================

  static Future<List<dynamic>> getSavings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/savings'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? [];
    }

    throw Exception(body['message'] ?? 'Gagal mengambil data tabungan');
  }

  static Future<Map<String, dynamic>> getSavingDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/savings/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? {};
    }

    throw Exception(body['message'] ?? 'Gagal mengambil detail tabungan');
  }

  static Future<Map<String, dynamic>> createSaving({
    required String name,
    required double targetAmount,
    String? category,
    String? targetDate,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/savings'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'target_amount': targetAmount,
        'category': category,
        'target_date': targetDate,
        'description': description,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return body['data'] ?? {};
    }

    throw Exception(body['message'] ?? 'Gagal membuat target tabungan');
  }

  static Future<void> addSavingDeposit({
    required int savingId,
    required double amount,
    required String date,
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/savings/$savingId/deposits'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'date': date,
        'note': note,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Gagal menyetor tabungan');
  }

  static Future<void> deleteSaving(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/savings/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Gagal menghapus tabungan');
  }

  static Future<List<dynamic>> getSavingDeposits(int savingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/savings/$savingId/deposits'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? [];
    }

    throw Exception(body['message'] ?? 'Gagal mengambil riwayat setoran');
  }

  // =====================================================
  // CHAT BOT QUICK ENTRY
  // =====================================================

  static Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat-bot/parse-and-save'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message'] ?? 'Format pesan tidak dikenali atau gagal diproses',
    );
  }

  // =====================================================
  // UTANG & PIUTANG (DEBTS)
  // =====================================================

  static Future<Map<String, dynamic>> getDebts({
    String? type,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/debts').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return {
        'data': body['data'] as List<dynamic>? ?? [],
        'summary': body['summary'] as Map<String, dynamic>? ?? {},
      };
    }

    throw Exception(body['message'] ?? 'Gagal memuat data utang piutang');
  }

  static Future<Map<String, dynamic>> createDebt({
    required String type,
    required String personName,
    required double amount,
    String? dueDate,
    String? description,
    String? date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/debts'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'person_name': personName,
        'amount': amount,
        'date': date,
        'due_date': dueDate,
        'description': description,
      }),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      return body['data'];
    }

    throw Exception(body['message'] ?? 'Gagal menyimpan utang/piutang');
  }

  static Future<Map<String, dynamic>> payDebt(
    int id, {
    double? amount,
    int? walletId,
    String? source,
    String? date,
    String? description,
  }) async {
    final Map<String, dynamic> payload = {};
    if (amount != null && amount > 0) payload['amount'] = amount;
    if (walletId != null) payload['wallet_id'] = walletId;
    if (source != null && source.isNotEmpty) payload['source'] = source;
    if (date != null && date.isNotEmpty) payload['date'] = date;
    if (description != null && description.isNotEmpty) payload['description'] = description;

    final response = await http.post(
      Uri.parse('$baseUrl/debts/$id/pay'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }

    throw Exception(body['message'] ?? 'Gagal memproses pembayaran');
  }

  static Future<void> deleteDebt(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/debts/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Gagal menghapus');
  }

  // =====================================================
  // EXPORT LAPORAN (PDF & EXCEL)
  // =====================================================

  static Future<File> downloadReport({
    required int year,
    int? month,
    required String format, // 'pdf' or 'excel'
  }) async {
    final queryParams = <String, String>{
      'year': year.toString(),
      'format': format,
    };
    if (month != null && month > 0) {
      queryParams['month'] = month.toString();
    }

    final headers = {
      'Accept': '*/*',
      'Authorization': 'Bearer $token',
    };
    final query = Uri(queryParameters: queryParams).query;
    var response = await http.get(
      Uri.parse('$baseUrl/reports/export?$query'),
      headers: headers,
    );

    // Compatibilidad con instalaciones donde la ruta sigue bajo /auth.
    if (response.statusCode == 404) {
      response = await http.get(
        Uri.parse('$baseUrl/auth/reports/export?$query'),
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      final ext = (format.toLowerCase() == 'excel' || format.toLowerCase() == 'xlsx') ? 'xlsx' : 'pdf';
      final fileName = month != null && month > 0
          ? 'Laporan_Keuangan_${month}_$year.$ext'
          : 'Laporan_Keuangan_Tahun_$year.$ext';

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }

    throw Exception('Gagal mengunduh laporan (Status ${response.statusCode})');
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  static Future<void> logout() async {
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      token = null;
    }
  }

  // =====================================================
  // DOMPET / SUMBER DANA (FR-100 s/d FR-111)
  // =====================================================

  static Future<Map<String, dynamic>> getWallets({bool includeArchived = false}) async {
    final query = includeArchived ? '?include_archived=1' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/wallets$query'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? {};
    }
    throw Exception(body['message'] ?? 'Gagal mengambil data dompet');
  }

  static Future<Map<String, dynamic>> createWallet({
    required String name,
    required String type,
    double initialBalance = 0,
    String? color,
    String? icon,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallets'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'type': type,
        'initial_balance': initialBalance,
        'color': color ?? '#10B981',
        'icon': icon ?? 'cash',
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 && body['success'] == true) {
      return body['data'] ?? {};
    }
    throw Exception(body['message'] ?? 'Gagal menambahkan dompet');
  }

  static Future<Map<String, dynamic>> updateWallet(
    int id, {
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/wallets/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'type': type,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] ?? {};
    }
    throw Exception(body['message'] ?? 'Gagal memperbarui dompet');
  }

  static Future<Map<String, dynamic>> archiveWallet(int id, {int? transferToWalletId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallets/$id/archive'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (transferToWalletId != null) 'transfer_to_wallet_id': transferToWalletId,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }
    throw Exception(body['message'] ?? 'Gagal mengarsipkan dompet');
  }

  static Future<Map<String, dynamic>> transferWallet({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    double adminFee = 0,
    bool allowNegative = false,
    String? notes,
    DateTime? date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallets/transfer'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'from_wallet_id': fromWalletId,
        'to_wallet_id': toWalletId,
        'amount': amount,
        'admin_fee': adminFee,
        'allow_negative': allowNegative,
        'notes': notes,
        if (date != null) 'date': date.toIso8601String(),
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 && body['success'] == true) {
      return body;
    }
    throw Exception(body['message'] ?? 'Gagal melakukan transfer antar dompet');
  }

  static Future<Map<String, dynamic>> adjustWalletBalance(int id, double realBalance) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallets/$id/adjust'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'real_balance': realBalance,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }
    throw Exception(body['message'] ?? 'Gagal menyesuaikan saldo');
  }

  static Future<Map<String, dynamic>> getWalletTransactions(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallets/$id/transactions'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      if (body['data'] is List) {
        return {'transactions': body['data']};
      } else if (body['data'] is Map<String, dynamic>) {
        return body['data'];
      }
      return {'transactions': []};
    }
    throw Exception(body['message'] ?? 'Gagal mengambil mutasi dompet');
  }
}