import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../services/api_service.dart';
import '../services/demo_repository.dart';

class KycController extends GetxController {
  final ApiService api;
  KycController(this.api);
  final rows = <Map<String, dynamic>>[].obs;
  final types = <String>[].obs;
  final selectedType = ''.obs,
      status = ''.obs,
      fileName = ''.obs,
      error = ''.obs;
  final bytes = Rxn<Uint8List>();
  final loading = false.obs, submitting = false.obs;
  final progress = 0.0.obs;
  int? maxBytes;
  int _request = 0;
  String safeError(Object exception) {
    if (exception is DioException) {
      if (exception.response?.statusCode == 401)
        return 'Your session expired. Sign in again.';
      final data = exception.response?.data;
      if (data is Map && data['message'] is String) return data['message'];
      if ([
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ].contains(exception.type))
        return 'The upload timed out. Refresh your KYC status before retrying.';
    }
    return 'Unable to complete the KYC request. Check your connection and retry.';
  }

  Future<void> load() async {
    final request = ++_request;
    loading.value = true;
    error.value = '';
    try {
      final data = await Future.wait<dynamic>([
        api.kycConfig(),
        api.kycStatus(),
        api.kyc(),
      ]);
      if (request != _request || isClosed) return;
      maxBytes = (data[0]['maxBytes'] as num).toInt();
      types.assignAll((data[0]['documentTypes'] as List).cast<String>());
      if (!types.contains(selectedType.value)) selectedType.value = types.first;
      status.value = data[1]['status'] as String;
      rows.assignAll(
        (data[2] as List).map((v) => Map<String, dynamic>.from(v as Map)),
      );
    } catch (e) {
      if (request == _request && !isClosed) error.value = safeError(e);
    } finally {
      if (request == _request && !isClosed) loading.value = false;
    }
  }

  String? get selectionError {
    if (maxBytes == null || types.isEmpty)
      return 'Load the upload requirements first.';
    if (bytes.value == null) return 'Select a document.';
    if (bytes.value!.isEmpty || bytes.value!.length > maxBytes!)
      return 'Select a document within the upload size limit.';
    final latest = rows.firstWhereOrNull(
      (r) => r['documentType'] == selectedType.value,
    );
    if (latest != null && ['PENDING', 'VERIFIED'].contains(latest['status']))
      return 'This document is already pending or verified.';
    return null;
  }

  void selectFile(String name, Uint8List value) {
    error.value = '';
    if (maxBytes == null || value.isEmpty || value.length > maxBytes!) {
      error.value =
          'Select a PDF, PNG or JPEG within the configured size limit.';
      return;
    }
    final pdf =
        value.length >= 5 && String.fromCharCodes(value.take(5)) == '%PDF-';
    final png =
        value.length >= 8 &&
        value[0] == 137 &&
        value[1] == 80 &&
        value[2] == 78 &&
        value[3] == 71;
    final jpg =
        value.length >= 3 &&
        value[0] == 255 &&
        value[1] == 216 &&
        value[2] == 255;
    if (!pdf && !png && !jpg) {
      error.value = 'Unsupported document. Use a PDF, PNG or JPEG.';
      return;
    }
    fileName.value = name;
    bytes.value = value;
  }

  void removeFile() {
    if (!submitting.value) {
      bytes.value = null;
      fileName.value = '';
    }
  }

  Future<bool> submit() async {
    if (submitting.value) return false;
    final validation = selectionError;
    if (validation != null) {
      error.value = validation;
      return false;
    }
    submitting.value = true;
    progress.value = 0;
    error.value = '';
    try {
      await api.submitKyc(
        selectedType.value,
        bytes.value!,
        fileName.value,
        onSendProgress: (sent, total) {
          if (!isClosed && total > 0) progress.value = sent / total;
        },
      );
      bytes.value = null;
      fileName.value = '';
      status.value = 'PENDING';
      await load();
      if (Get.isRegistered<DemoRepository>())
        Get.find<DemoRepository>().syncFromBackend().catchError((_) {});
      return true;
    } catch (e) {
      error.value = safeError(e);
      return false;
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    _request++;
    bytes.value = null;
    super.onClose();
  }
}
