class VehicleData {
  final String type;
  final String number;
  final String model;
  final String color;
  final String brand;
  final int year;

  const VehicleData({
    required this.type,
    required this.number,
    required this.model,
    this.color = '',
    this.brand = '',
    this.year = 0,
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      type: json['type'] ?? '',
      number: json['number'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      brand: json['brand'] ?? '',
      year: json['year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'number': number,
      'model': model,
      'color': color,
      'brand': brand,
      'year': year,
    };
  }

  VehicleData copyWith({
    String? type,
    String? number,
    String? model,
    String? color,
    String? brand,
    int? year,
  }) {
    return VehicleData(
      type: type ?? this.type,
      number: number ?? this.number,
      model: model ?? this.model,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      year: year ?? this.year,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleData &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          number == other.number &&
          model == other.model &&
          color == other.color &&
          brand == other.brand &&
          year == other.year;

  @override
  int get hashCode =>
      type.hashCode ^
      number.hashCode ^
      model.hashCode ^
      color.hashCode ^
      brand.hashCode ^
      year.hashCode;

  @override
  String toString() {
    return 'VehicleData{type: $type, number: $number, model: $model, color: $color, brand: $brand, year: $year}';
  }
}
