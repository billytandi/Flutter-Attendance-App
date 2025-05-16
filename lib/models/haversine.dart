import 'dart:math';

double rangeKantor(double lat2, double lon2) {
  const double R = 6371e3; // Radius bumi dalam meter

  double lat1 = -6.112721;
  double lon1 = 106.881920;
  double phi1 = lat1 * (3.141592653589793238 / 180); // Konversi ke radian
  double phi2 = lat2 * (3.141592653589793238 / 180);
  double deltaPhi = (lat2 - lat1) * (3.141592653589793238 / 180);
  double deltaLambda = (lon2 - lon1) * (3.141592653589793238 / 180);

  double a = ( (sin(deltaPhi / 2)) * (sin(deltaPhi / 2))) +
             (cos(phi1) * cos(phi2) * (sin(deltaLambda / 2)) * (sin(deltaLambda / 2)));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // Jarak dalam meter
}


double rangeKampus(double lat2, double lon2) {
  const double R = 6371e3; // Radius bumi dalam meter
  double lat1 = -6.316056;
  double lon1 = 106.79497;
  double phi1 = lat1 * (3.141592653589793238 / 180); // Konversi ke radian
  double phi2 = lat2 * (3.141592653589793238 / 180);
  double deltaPhi = (lat2 - lat1) * (3.141592653589793238 / 180);
  double deltaLambda = (lon2 - lon1) * (3.141592653589793238 / 180);

  double a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
             (cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // Jarak dalam meter
}

double rangeDDN(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371e3; // Radius bumi dalam meter
  double phi1 = lat1 * (3.141592653589793238 / 180); // Konversi ke radian
  double phi2 = lat2 * (3.141592653589793238 / 180);
  double deltaPhi = (lat2 - lat1) * (3.141592653589793238 / 180);
  double deltaLambda = (lon2 - lon1) * (3.141592653589793238 / 180);

  double a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
             (cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // Jarak dalam meter
}
