import '../constants/app_constants.dart';

/// Check fee based on distance:
/// 0 - 3 km: Rs 200
/// 3 - 7 km: Rs 400
/// 7 - 10 km: Rs 600
/// > 10 km: Rs 600
int checkFeeForDistanceKm(double distanceKm) {
  if (distanceKm <= 3) return 200;
  if (distanceKm <= 7) return 400;
  return 600;
}

String checkFeeLabel(double distanceKm) {
  final fee = checkFeeForDistanceKm(distanceKm);
  return 'Rs $fee check fee';
}
