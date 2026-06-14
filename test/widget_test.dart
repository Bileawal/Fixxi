import 'package:flutter_test/flutter_test.dart';
import 'package:fixxi/core/constants/app_constants.dart';

void main() {
  test('check fee within 4km is 300', () {
    expect(AppConstants.checkFeeWithin4Km, 300);
  });
}
