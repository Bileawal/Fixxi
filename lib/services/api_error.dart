import 'package:dio/dio.dart';

String friendlyApiError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Cannot connect to server. Please start the backend first:\n'
            'cd backend → npm run dev\n'
            'MongoDB must also be running.';
      case DioExceptionType.connectionError:
        return 'Internet / server connection error. Is the backend running? '
            'Emulator: 10.0.2.2:3000 | Phone: PC Wi-Fi IP:3000';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
        return 'Server error (${error.response?.statusCode ?? '?'})';
      default:
        return error.message ?? error.toString();
    }
  }
  return error.toString();
}
