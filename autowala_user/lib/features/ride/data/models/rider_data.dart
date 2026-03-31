import 'location_data.dart';
import 'vehicle_data.dart';

class RiderData {
  final String id;
  final String name;
  final String phone;
  final VehicleData vehicle;
  final double rating;
  final String avatar;
  final LocationData location;
  final String status;
  final bool isVerified;

  const RiderData({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.rating,
    required this.avatar,
    required this.location,
    this.status = 'online',
    this.isVerified = false,
  });

  factory RiderData.fromJson(Map<String, dynamic> json) {
    return RiderData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicle: VehicleData.fromJson(json['vehicle'] ?? {}),
      rating: (json['rating'] ?? 0.0).toDouble(),
      avatar: json['avatar'] ?? '',
      location: LocationData.fromJson(json['location'] ?? {}),
      status: json['status'] ?? 'online',
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'vehicle': vehicle.toJson(),
      'rating': rating,
      'avatar': avatar,
      'location': location.toJson(),
      'status': status,
      'is_verified': isVerified,
    };
  }

  RiderData copyWith({
    String? id,
    String? name,
    String? phone,
    VehicleData? vehicle,
    double? rating,
    String? avatar,
    LocationData? location,
    String? status,
    bool? isVerified,
  }) {
    return RiderData(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      rating: rating ?? this.rating,
      avatar: avatar ?? this.avatar,
      location: location ?? this.location,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiderData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          vehicle == other.vehicle &&
          rating == other.rating &&
          avatar == other.avatar &&
          location == other.location &&
          status == other.status &&
          isVerified == other.isVerified;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      vehicle.hashCode ^
      rating.hashCode ^
      avatar.hashCode ^
      location.hashCode ^
      status.hashCode ^
      isVerified.hashCode;

  @override
  String toString() {
    return 'RiderData{id: $id, name: $name, phone: $phone, vehicle: $vehicle, rating: $rating, avatar: $avatar, location: $location, status: $status, isVerified: $isVerified}';
  }
}
