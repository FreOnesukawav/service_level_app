class SheetData {
  final String date;
  final double ohladeniePercent;
  final double zamorozkaPercent;
  final double frovPercent;

  SheetData({
    required this.date,
    required this.ohladeniePercent,
    required this.zamorozkaPercent,
    required this.frovPercent,
  });

  DateTime get parsedDate {
    try {
      final parts = date.split('.').map((e) => int.parse(e)).toList();
      // Format is dd.MM.yyyy, so parts are [day, month, year]
      return DateTime(parts[2], parts[1], parts[0]);
    } catch (e) {
      // Return a default date far in the past if parsing fails
      return DateTime(2000);
    }
  }

  factory SheetData.fromJson(Map<String, dynamic> json) {
    return SheetData(
      date: json['date'],
      ohladeniePercent: json['ohladeniePercent'],
      zamorozkaPercent: json['zamorozkaPercent'],
      frovPercent: json['frovPercent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'ohladeniePercent': ohladeniePercent,
      'zamorozkaPercent': zamorozkaPercent,
      'frovPercent': frovPercent,
    };
  }
}
