import 'package:dio/dio.dart';

class ApiConfig {
  static String _baseUrl = defaultEmulatorUrl;

  static const defaultEmulatorUrl = 'http://10.0.2.2:3000';
  static const defaultLanUrl = 'http://192.168.1.7:3000';

  static String get apiBase => _baseUrl;
  static String get authBase => '$apiBase/api/auth/';
  static String get adminBase => '$apiBase/api/admin/';
  static String get testBase => '$apiBase/api/test/';
  static String get api => '$apiBase/api/';

  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static List<String> get candidateUrls => [
        defaultEmulatorUrl,
        defaultLanUrl,
        'http://127.0.0.1:3000',
      ];

  static Future<bool> ping(String baseUrl) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await dio.get('$baseUrl/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> discoverServer({String? savedUrl}) async {
    if (savedUrl != null && await ping(savedUrl)) {
      setBaseUrl(savedUrl);
      return savedUrl;
    }
    for (final url in candidateUrls) {
      if (await ping(url)) {
        setBaseUrl(url);
        return url;
      }
    }
    return null;
  }
}
