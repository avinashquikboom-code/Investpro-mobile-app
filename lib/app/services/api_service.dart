import 'api_diagnostics.dart';
import 'payment_error.dart';
import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;

class ProjectPage {
  final List<Map<String, dynamic>> projects;
  final int page;
  final int totalPages;
  final bool subscriptionRequired;
  final Map<String, dynamic>? eligibility;

  const ProjectPage(
    this.projects, {
    required this.page,
    required this.totalPages,
    this.subscriptionRequired = false,
    this.eligibility,
  });
}

class ApiService extends getx.GetxService {
  int sessionVersion = 0;
  DateTime? _nextReadAt;
  DateTime? get nextReadAt => _nextReadAt;
  VoidCallback? onSessionExpired;
  bool _expirationNotified=false;

  static const String _keyAccessToken = 'investpro_access_token';
  static const String _keyRefreshToken = 'investpro_refresh_token';

  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

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
          if (options.method == 'GET' &&
              _nextReadAt?.isAfter(DateTime.now()) == true) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 429,
                  data: {'message': 'Please wait before refreshing again.'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          }
          if (!options.path.contains('/auth/login') &&
              !options.path.contains('/auth/refresh')) {
            final token = await getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 429) {
            final retry = ApiDiagnostics.retryAt(
              error.response?.headers.value('retry-after'),
              DateTime.now(),
            );
            if (_nextReadAt == null || retry.isAfter(_nextReadAt!)) {
              _nextReadAt = retry;
            }
          }
          ApiDiagnostics.log(error);

          final is401 = error.response?.statusCode == 401;
          final isAuthEndpoint =
              error.requestOptions.path.contains('/auth/login') ||
                  error.requestOptions.path.contains('/auth/refresh');
          final isAlreadyRetry = error.requestOptions.extra['retry'] == true;

          if (is401 && !isAuthEndpoint && !isAlreadyRetry) {
            try {
              final current = await getAccessToken();
              final sent = error.requestOptions.headers['Authorization'];
              final bool refreshed = (current != null &&
                      current.isNotEmpty &&
                      sent != 'Bearer $current') ||
                  await _refreshToken();

              if (refreshed) {
                final token = await getAccessToken();
                final retryOptions = error.requestOptions;
                retryOptions.extra['retry'] = true;
                retryOptions.headers['Authorization'] = 'Bearer $token';
                if (retryOptions.data is FormData) {
                  retryOptions.data = (retryOptions.data as FormData).clone();
                }
                try {
                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                } on DioException catch (retryError) {
                  if (retryError.response?.statusCode == 401) {
                    await _expireSession();
                  }
                  return handler.next(retryError);
                }
              }
            } on DioException catch (refreshError) {
              return handler.next(refreshError);
            } catch (_) {
              return handler.next(error);
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
    _expirationNotified=false;
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> clearTokens() async {
    sessionVersion++;
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  Future<bool>? _refreshing;
  Future<bool> _refreshToken() => _refreshing ??= _performRefreshToken().whenComplete(() => _refreshing = null);
  Future<bool> _performRefreshToken() async {
    final rToken = await getRefreshToken();
    if (rToken == null || rToken.isEmpty) {
      await _expireSession();
      return false;
    }

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
    } on DioException catch(error) {
      if(error.response?.statusCode==401||error.response?.statusCode==403){await _expireSession();return false;}
      rethrow;
    }
    throw const FormatException('Invalid session refresh response');
  }
  Future<void> _expireSession() async {
    await clearTokens();
    if(!_expirationNotified){_expirationNotified=true;onSessionExpired?.call();}
  }

  Future<List<dynamic>> collection(String path, {Map<String, dynamic>? query}) async {
    final records = <dynamic>[];
    for (var page = 1; ; page++) {
      final response = await dio.get(path, queryParameters: {...?query, 'page': page, 'limit': 100});
      if (response.data['success'] != true || response.data['data'] is! List) throw Exception('Unable to load records');
      records.addAll(response.data['data'] as List);
      if (page >= ((response.data['meta']?['totalPages'] as num?)?.toInt() ?? 1)) return records;
    }
  }
  Future<Map<String, dynamic>> object(String path) async {
    final response = await dio.get(path);
    if (response.data['success'] != true || response.data['data'] is! Map) throw Exception('Unable to load account data');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
  Future<Map<String,dynamic>> _paymentPost(String path,Map<String,dynamic> data,{String? requestId}) async {
    try {
      final response=await dio.post(path,data:data,options:Options(headers:{'Idempotency-Key':?requestId},receiveTimeout:const Duration(seconds:50)));
      if(response.data is! Map || response.data['success']!=true || response.data['data'] is! Map)throw const PaymentFailure('The payment service returned an invalid response. Retry safely.');
      return Map<String,dynamic>.from(response.data['data'] as Map);
    } catch(error) {
      final message=PaymentError.message(error);
      if(kDebugMode){final status=error is DioException?error.response?.statusCode:null;debugPrint('Payment request failed method=POST url=${dio.options.baseUrl}$path status=${status??'network/invalid response'} response=${jsonEncode({'message':PaymentError.diagnostic(message)})}');}
      throw PaymentFailure(message);
    }
  }
  Future<Map<String,dynamic>> paymentOrder(String investmentId)=>_paymentPost('/payments/orders',{'investmentId':investmentId});
  Future<Map<String,dynamic>> verifyPayment(Map<String,dynamic> data)=>_paymentPost('/payments/verify',data);

  Future<List<dynamic>> kyc() => collection('/mobile/kyc');
  Future<Map<String, dynamic>> kycConfig() => object('/mobile/kyc/config');
  Future<Map<String, dynamic>> kycStatus() => object('/mobile/kyc/status');
  Future<Map<String, dynamic>> submitKyc(String type, List<int> bytes, String name, {void Function(int, int)? onSendProgress}) async {
    String? mimeType;
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) {
      mimeType = 'application/pdf';
    } else if (lower.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    }
    final file = MultipartFile.fromBytes(
      bytes,
      filename: name,
      contentType: mimeType != null ? DioMediaType.parse(mimeType) : null,
    );
    final response = await dio.post(
      '/mobile/kyc',
      data: FormData.fromMap({'documentType': type, 'document': file}),
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
      onSendProgress: onSendProgress,
    );
    if (response.data['success'] != true || response.data['data']?['id'] == null) throw StateError('The server did not confirm KYC persistence');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
  Future<String> kycDocumentUrl(String id) async => (await object('/mobile/kyc/$id/document'))['url'] as String;
  Future<void> changePassword(String current, String next) async { await dio.post('/auth/change-password', data: {'currentPassword': current, 'newPassword': next}); }

  // --- AUTH APIS ---

  Future<Map<String, dynamic>> sendRegistrationOtp({
    required String mobileNumber,
    String? email,
    String? fullName,
  }) async {
    try {
      final response = await dio.post(
        '/auth/registration/send-otp',
        data: {
          'mobileNumber': mobileNumber.trim(),
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          if (fullName != null && fullName.isNotEmpty) 'fullName': fullName.trim(),
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw StateError(response.data?['message'] ?? 'Unable to send OTP');
    } catch (e) {
      debugPrint('[ApiService] sendRegistrationOtp error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    required String otp,
  }) async {
    sessionVersion++;
    try {
      final response = await dio.post(
        '/auth/registration/verify-otp',
        data: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'mobileNumber': mobileNumber.trim(),
          'password': password,
          'otp': otp.trim(),
        },
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;
        await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        return data;
      }
      throw StateError(response.data?['message'] ?? 'Unable to verify OTP');
    } catch (e) {
      debugPrint('[ApiService] verifyRegistrationOtp error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> login(
    String emailOrMobile,
    String password,
  ) async {
    sessionVersion++;
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
    sessionVersion++;
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

  Future<Map<String, dynamic>?> forgotPassword(String identifier) async {
    try {
      final response = await dio.post(
        '/auth/forgot-password',
        data: {
          'email': identifier.trim(),
          'identifier': identifier.trim(),
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as Map<String, dynamic>?) ?? {};
      }
    } catch (e) {
      debugPrint('[ApiService] forgotPassword error: $e');
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> verifyResetCode({
    required String identifier,
    required String otp,
  }) async {
    try {
      final response = await dio.post(
        '/auth/verify-reset-code',
        data: {
          'email': identifier.trim(),
          'identifier': identifier.trim(),
          'otp': otp.trim(),
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as Map<String, dynamic>?) ?? {};
      }
    } catch (e) {
      debugPrint('[ApiService] verifyResetCode error: $e');
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        '/auth/reset-password',
        data: {
          'email': identifier.trim(),
          'identifier': identifier.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as Map<String, dynamic>?) ?? {};
      }
    } catch (e) {
      debugPrint('[ApiService] resetPassword error: $e');
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
    final response = await dio.get('/auth/me');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    return null;
  }

  // --- MOBILE DASHBOARD & DATA ---

  Future<Map<String, dynamic>?> getDashboard() async => object('/mobile/dashboard');


  Future<List<Map<String, dynamic>>> getProjectCategories() async {
    final response = await dio.get('/mobile/project-categories');
    if (response.data['success'] != true || response.data['data'] is! List) {
      throw Exception('Unable to load categories');
    }
    return (response.data['data'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<ProjectPage> getEligibleProjectPage({
    int page = 1,
    int limit = 12,
    String? projectTypeId,
    String? search,
  }) async {
    final response = await dio.get(
      '/mobile/projects',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (projectTypeId != null && projectTypeId.isNotEmpty)
          'projectTypeId': projectTypeId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final isList = response.data['data'] is List;
    final isMap = response.data['data'] is Map;
    if (response.data['success'] != true || (!isList && !isMap)) {
      throw Exception('Unable to load projects');
    }
    final rawProjects = isList
        ? response.data['data'] as List
        : (response.data['data']['projects'] as List? ?? []);
    final records = rawProjects
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
    final pages = (response.data['meta']?['totalPages'] as num?)?.toInt() ?? 1;
    final subReq = response.data['meta']?['subscriptionRequired'] == true ||
        (isMap && response.data['data']?['subscriptionRequired'] == true);
    final elig = (response.data['meta']?['eligibility'] as Map?) != null
        ? Map<String, dynamic>.from(response.data['meta']['eligibility'] as Map)
        : (isMap && response.data['data']?['eligibility'] is Map
            ? Map<String, dynamic>.from(
                response.data['data']['eligibility'] as Map)
            : null);
    return ProjectPage(
      records,
      page: page,
      totalPages: pages,
      subscriptionRequired: subReq,
      eligibility: elig,
    );
  }

  Future<Map<String, dynamic>> getOnboarding() => object('/mobile/onboarding');
  Future<void> skipSubscriptionOnboarding() async {
    final response = await dio.patch('/mobile/onboarding', data: {'action': 'skip'});
    if (response.data['success'] != true) throw StateError('Unable to save onboarding choice');
  }

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    final response = await dio.get('/mobile/subscription/plans');
    if (response.data['success'] != true || response.data['data'] is! List) {
      throw Exception('Unable to load subscription plans');
    }
    return (response.data['data'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final response = await dio.get('/mobile/subscription/current');
    if (response.data['success'] == true && response.data['data'] is Map) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    final response = await dio.get('/mobile/subscription/history');
    if (response.data['success'] == true && response.data['data'] is List) {
      return (response.data['data'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getSubscriptionEligibility() async {
    final response = await dio.get('/mobile/subscription/eligibility');
    if (response.data['success'] == true && response.data['data'] is Map) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
    throw Exception('Unable to check subscription eligibility');
  }

  Future<Map<String, dynamic>> purchaseSubscription({
    required String planId,
    String paymentMethod = 'UPI',
    String? idempotencyKey,
  }) async {
    final response = await dio.post(
      '/mobile/subscription/purchase',
      data: {
        'planId': planId,
        'paymentMethod': paymentMethod,
        'idempotencyKey': ?idempotencyKey,
      },
    );
    if (response.data['success'] != true || response.data['data'] is! Map) {
      throw Exception(
        response.data['message']?.toString() ??
            'Unable to initiate subscription purchase',
      );
    }
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> verifySubscriptionPayment(
    Map<String, dynamic> paymentData,
  ) async {
    final response = await dio.post(
      '/mobile/subscription/verify-payment',
      data: paymentData,
    );
    if (response.data['success'] != true || response.data['data'] is! Map) {
      throw Exception(
        response.data['message']?.toString() ??
            'Unable to verify subscription payment',
      );
    }
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getEligibleProjects({
    String? projectTypeId,
    String? search,
  }) async {
    final records = <Map<String, dynamic>>[];
    for (var page = 1; ; page++) {
      final result = await getEligibleProjectPage(
        page: page,
        limit: 100,
        projectTypeId: projectTypeId,
        search: search,
      );
      records.addAll(result.projects);
      if (page >= result.totalPages) return records;
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

  Future<Map<String,dynamic>?> getProject(String id)=>object('/mobile/projects/$id');

  Future<List<dynamic>?> getInvestments() async => collection('/mobile/investments');


  Future<Map<String, dynamic>?> createInvestment({
    required String projectId,
    required double amount,
    String? idempotencyKey,
    String paymentMethod = 'BANK_TRANSFER',
  }) async {
    return _paymentPost('/mobile/investments',{'projectId':projectId,'amount':amount,'paymentMethod':paymentMethod},requestId:idempotencyKey);
  }

  Future<Map<String, dynamic>> getReturnsWorkspace(String period) =>
      object('/mobile/returns/summary?period=${Uri.encodeQueryComponent(period.toLowerCase())}');

  Future<List<dynamic>?> getReturns() async => collection('/mobile/returns');


  Future<Map<String, dynamic>> getWallet() async => object('/mobile/wallet');

  Future<({List<Map<String, dynamic>> rows, int totalPages})> getWalletHistory({int page = 1, String filter = 'All'}) async {
    final response = await dio.get('/mobile/wallet/transactions', queryParameters: {'page': page, 'limit': 15, 'filter': filter});
    if (response.data['success'] != true || response.data['data'] is! List) {
      throw StateError('Wallet history unavailable');
    }
    return (
      rows: (response.data['data'] as List).map((v) => Map<String, dynamic>.from(v as Map)).toList(),
      totalPages: (response.data['meta']?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<Map<String, dynamic>> getWalletTransaction(String id) async => object('/mobile/wallet/transactions/${Uri.encodeComponent(id)}');

  Future<List<dynamic>?> getWithdrawals() async => collection('/mobile/withdrawals');


  Future<Map<String, dynamic>?> createWithdrawal({
    required double amount,
    String? exactAmount,
    String? projectId,
    bool returnsOnly = false,
    String? bankAccountId,
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      final payload = <String, dynamic>{'amount': exactAmount ?? amount};
      if (bankAccountId != null) payload['bankAccountId'] = bankAccountId;
      if (projectId != null) payload['projectId'] = projectId;
      if (returnsOnly) payload['returnsOnly'] = true;
      if (notes != null) payload['notes'] = notes;

      final response = await dio.post('/mobile/withdrawals', data: payload, options: Options(headers: {'Idempotency-Key': ?idempotencyKey}));

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

  Future<List<dynamic>?> getTransactions() async => collection('/mobile/transactions');


  Future<Map<String, dynamic>?> getProfile() async => object('/mobile/profile');


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

  static String newRequestKey() => base64UrlEncode(List.generate(24, (_) => Random.secure().nextInt(256)));
  Future<Map<String,dynamic>> submitRequest({required String kind, required String title, required String message, required String key}) async {
    final result = await dio.post('/mobile/requests',data:{'kind':kind,'title':title,'message':message},options:Options(headers:{'Idempotency-Key':key}));
    return Map<String,dynamic>.from(result.data['data'] as Map);
  }
  Future<List<dynamic>> requestHistory({int page=1}) async {
    final result=await dio.get('/mobile/requests',queryParameters:{'page':page});return result.data['data'] as List;
  }
  Future<Map<String,dynamic>> requestDetail(String id) => object('/mobile/requests/${Uri.encodeComponent(id)}');

  Future<List<dynamic>?> getNotifications() async {
    final result = await object('/mobile/notifications');
    if (result['notifications'] is! List) throw StateError('Unable to load notifications');
    return result['notifications'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getNotificationsPage(int page) async {
    final response = await dio.get('/mobile/notifications', queryParameters: {'page': page, 'limit': 50});
    return Map<String, dynamic>.from(response.data['data'] as Map);
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
