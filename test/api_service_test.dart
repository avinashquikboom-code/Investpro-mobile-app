import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService Tests', () {
    test('defaultBaseUrl returns valid HTTP URL', () {
      final url = ApiService.defaultBaseUrl;
      expect(url.startsWith('http://'), isTrue);
      expect(url.contains('5000/api/v1'), isTrue);
    });

    test('ApiService initializes Dio instance', () async {
      final api = ApiService();
      await api.init(baseUrl: 'http://localhost:5000/api/v1');
      expect(api.dio.options.baseUrl, 'http://localhost:5000/api/v1');
      expect(api.dio.options.headers['Content-Type'], 'application/json');
    });
  });
}

