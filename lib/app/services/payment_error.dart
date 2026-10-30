import 'package:dio/dio.dart';

class PaymentFailure implements Exception {
  const PaymentFailure(this.message);
  final String message;
  @override String toString()=>message;
}
class PaymentError {
  static String message(Object error,{String fallback='Unable to initiate payment. Please retry.'}) {
    if(error is PaymentFailure)return error.message;
    if(error is DioException){
      final status=error.response?.statusCode;
      if(status==401)return 'Your session has expired. Please sign in again.';
      if(status==403)return 'This account is not allowed to make this payment.';
      if(error.type==DioExceptionType.connectionTimeout||error.type==DioExceptionType.receiveTimeout||error.type==DioExceptionType.sendTimeout||error.type==DioExceptionType.connectionError)return 'Unable to reach the payment service. Your request is saved; retry safely.';
      final data=error.response?.data;
      if(data is Map){
        final fields=data['errors'];
        if(fields is List&&fields.isNotEmpty){final messages=fields.whereType<Map>().map((field)=>field['message']).whereType<String>().where((s)=>s.isNotEmpty);if(messages.isNotEmpty)return messages.join(' ').substring(0,messages.join(' ').length.clamp(0,300));}
        final provider=data['error'];
        final text=data['message']??(provider is Map?provider['description']:null);
        if(text is String&&text.trim().isNotEmpty)return text.substring(0,text.length.clamp(0,300));
      }
      return fallback;
    }
    if(error is ArgumentError&&error.message is String)return error.message as String;
    return fallback;
  }
  static String diagnostic(String value)=>value.replaceAll(RegExp(r'Bearer\s+\S+',caseSensitive:false),'[redacted]').replaceAll(RegExp(r'[A-Za-z0-9_\-]{30,}'),'[redacted]').replaceAll(RegExp(r'[^\s@]+@[^\s@]+'),'[redacted]').replaceAll(RegExp(r'\d{10,}'),'[redacted]');
}
