/// Réponse agrégée de GET /drivers/earnings?period=...
class DriverPeriodEarnings {
  final String period;
  final double total;
  final int rides;
  final int averagePerRide;
  final double totalDistanceKm;
  final int totalDurationMinutes;

  const DriverPeriodEarnings({
    required this.period,
    required this.total,
    required this.rides,
    required this.averagePerRide,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
  });

  factory DriverPeriodEarnings.fromApi(Map<String, dynamic> data) {
    final e = data['earnings'];
    final map = e is Map<String, dynamic> ? e : <String, dynamic>{};
    return DriverPeriodEarnings(
      period: data['period']?.toString() ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0,
      rides: (map['rides'] as num?)?.toInt() ?? 0,
      averagePerRide: (map['average'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 0,
      totalDurationMinutes: (map['totalDurationMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  String get totalFormatted => '${total.toStringAsFixed(0)} FCFA';

  String get distanceFormatted =>
      totalDistanceKm >= 1 ? '${totalDistanceKm.toStringAsFixed(1)} km' : '${(totalDistanceKm * 1000).toStringAsFixed(0)} m';

  String get durationFormatted {
    if (totalDurationMinutes <= 0) return '—';
    final h = totalDurationMinutes ~/ 60;
    final m = totalDurationMinutes % 60;
    if (h <= 0) return '$m min';
    return '${h}h ${m.toString().padLeft(2, "0")}min';
  }
}
