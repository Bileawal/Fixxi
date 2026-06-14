import '../constants/app_constants.dart';

/// Check fee: Rs 300 within 4 km, Rs 500 from 4 km up to 8 km.
int checkFeeForDistanceKm(double distanceKm) {
  if (distanceKm <= 4) return AppConstants.checkFeeWithin4Km;
  if (distanceKm <= 8) return AppConstants.checkFee4To8Km;
  return AppConstants.checkFee4To8Km;
}

String checkFeeLabel(double distanceKm) {
  final fee = checkFeeForDistanceKm(distanceKm);
  return 'Rs $fee check fee';
}
