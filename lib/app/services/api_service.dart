import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;

class ApiService extends getx.GetxService {
  static const String _keyAccessToken = 'investpro_access_token';
  static const String _keyRefreshToken = 'investpro_refresh_token';

  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String liveBaseUrl = 'https://api.qbunify.online/api/v1';

  static String get defaultBaseUrl => liveBaseUrl;

  Future<ApiService> init({String? baseUrl}) async {
    final url = baseUrl ?? defaultBaseUrl;
    dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['retry'] != true) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await getAccessToken();
              error.requestOptions.extra['retry'] = true;
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    return this;
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _keyRefreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  Future<bool> _refreshToken() async {
    final rToken = await getRefreshToken();
    if (rToken == null || rToken.isEmpty) return false;

    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': rToken},
        options: Options(extra: {'retry': true}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newAccess != null) {
          await saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh ?? rToken,
          );
          return true;
        }
      }
    } catch (_) {
      await clearTokens();
    }
    return false;
  }

  // --- AUTH APIS ---

  Future<Map<String, dynamic>?> login(
    String emailOrMobile,
    String password,
  ) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': emailOrMobile, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;
        await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        return data;
      }
    } catch (e) {
      debugPrint('[ApiService] login error: $e');
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'mobileNumber': mobileNumber,
          'password': password,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;
        await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        return data;
      }
    } catch (e) {
      debugPrint('[ApiService] register error: $e');
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    final rToken = await getRefreshToken();
    try {
      if (rToken != null) {
        await dio.post('/auth/logout', data: {'refreshToken': rToken});
      }
    } catch (_) {
    } finally {
      await clearTokens();
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await dio.get('/auth/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getMe error: $e');
    }
    return null;
  }

  // --- MOBILE DASHBOARD & DATA ---

  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await dio.get('/mobile/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getDashboard error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getProjectCategories() async {
    final response = await dio.get('/mobile/project-categories');
    if (response.data['success'] != true || response.data['data'] is! List) throw Exception('Unable to load categories');
    return (response.data['data'] as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getEligibleProjects({String? projectTypeId, String? search}) async {
    final records = <Map<String, dynamic>>[];
    for (var page = 1; ; page++) {
      final response = await dio.get('/mobile/projects', queryParameters: {
        'page': page, 'limit': 100,
        if (projectTypeId != null && projectTypeId.isNotEmpty) 'projectTypeId': projectTypeId,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      if (response.data['success'] != true || response.data['data'] is! List) throw Exception('Unable to load projects');
      records.addAll((response.data['data'] as List).map((v) => Map<String, dynamic>.from(v as Map)));
      final pages = (response.data['meta']?['totalPages'] as num?)?.toInt() ?? 1;
      if (page >= pages) return records;
    }
  }

  Future<List<dynamic>?> getProjects({String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{'limit': 50};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await dio.get(
        '/mobile/projects',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getProjects error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProject(String id) async {
    try {
      final response = await dio.get('/mobile/projects/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getProject error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getInvestments() async {
    try {
      final response = await dio.get('/mobile/investments');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getInvestments error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createInvestment({
    required String projectId,
    required double amount,
    String paymentMethod = 'BANK_TRANSFER',
  }) async {
    try {
      final response = await dio.post(
        '/mobile/investments',
        data: {
          'projectId': projectId,
          'amount': amount,
          'paymentMethod': paymentMethod,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] createInvestment error: $e');
      rethrow;
    }
    return null;
  }

  Future<List<dynamic>?> getReturns() async {
    try {
      final response = await dio.get('/mobile/returns');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getReturns error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getWithdrawals() async {
    try {
      final response = await dio.get('/mobile/withdrawals');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getWithdrawals error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createWithdrawal({
    required double amount,
    String? bankAccountId,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{'amount': amount};
      if (bankAccountId != null) payload['bankAccountId'] = bankAccountId;
      if (notes != null) payload['notes'] = notes;

      final response = await dio.post('/mobile/withdrawals', data: payload);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] createWithdrawal error: $e');
      rethrow;
    }
    return null;
  }

  Future<List<dynamic>?> getTransactions() async {
    try {
      final response = await dio.get('/mobile/transactions');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getTransactions error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await dio.get('/mobile/profile');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getProfile error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateProfile({
    String? fullName,
    String? mobileNumber,
    String? address,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (fullName != null) payload['fullName'] = fullName;
      if (mobileNumber != null) payload['mobileNumber'] = mobileNumber;
      if (address != null) payload['address'] = address;

      final response = await dio.patch('/mobile/profile', data: payload);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] updateProfile error: $e');
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getInvestmentStats() async {
    try {
      final response = await dio.get('/mobile/investments/stats');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getInvestmentStats error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getNotifications() async {
    try {
      final response = await dio.get('/mobile/notifications');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map && data.containsKey('notifications')) {
          return data['notifications'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getNotifications error: $e');
    }
    return null;
  }

  Future<int?> getUnreadNotificationCount() async {
    try {
      final response = await dio.get('/mobile/notifications/unread-count');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map && data.containsKey('unreadCount')) {
          return (data['unreadCount'] as num).toInt();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getUnreadNotificationCount error: $e');
    }
    return null;
  }

  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
    String? deviceId,
  }) async {
    try {
      final response = await dio.post(
        '/mobile/device-tokens',
        data: {'token': token, 'platform': platform, 'deviceId': ?deviceId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[ApiService] registerDeviceToken error: $e');
      return false;
    }
  }

  Future<bool> deleteDeviceToken(String token) async {
    try {
      final response = await dio.delete(
        '/mobile/device-tokens',
        data: {'token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] deleteDeviceToken error: $e');
      return false;
    }
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      final response = await dio.patch('/mobile/notifications/$id/read');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      final response = await dio.patch('/mobile/notifications/read-all');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>?> getBankAccounts() async {
    try {
      final response = await dio.get('/mobile/bank-accounts');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getBankAccounts error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String bankName,
    required String ifscCode,
    String? branchName,
    String accountType = 'SAVINGS',
    bool isPrimary = false,
  }) async {
    try {
      final response = await dio.post(
        '/mobile/bank-accounts',
        data: {
          'accountHolderName': accountHolderName,
          'accountNumber': accountNumber,
          'bankName': bankName,
          'ifscCode': ifscCode,
          'branchName': ?branchName,
          'accountType': accountType,
          'isPrimary': isPrimary,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] createBankAccount error: $e');
      rethrow;
    }
    return null;
  }
}
