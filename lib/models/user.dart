// mobile/lib/models/user.dart
import 'package:flutter/material.dart';

enum UserRole {
  client('client', 'Client', Icons.person, Colors.green),
  driver('driver', 'Chauffeur', Icons.delivery_dining, Colors.blue),
  admin('admin', 'Admin Garage', Icons.business, Colors.orange),
  superAdmin('super_admin', 'Super Admin', Icons.admin_panel_settings, Colors.red);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const UserRole(this.value, this.label, this.icon, this.color);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.client,
    );
  }
}

enum UserStatus {
  active('active', 'Actif', Colors.green),
  suspended('suspended', 'Suspendu', Colors.orange),
  deleted('deleted', 'Supprimé', Colors.red);

  final String value;
  final String label;
  final Color color;
  const UserStatus(this.value, this.label, this.color);
}

enum DriverStatus {
  available('available', 'Disponible', Colors.green),
  busy('busy', 'En course', Colors.orange),
  offline('offline', 'Hors ligne', Colors.red);

  final String value;
  final String label;
  final Color color;
  const DriverStatus(this.value, this.label, this.color);
}

enum Gender {
  male('male', 'Homme', Icons.male),
  female('female', 'Femme', Icons.female),
  other('other', 'Autre', Icons.person);

  final String value;
  final String label;
  final IconData icon;
  const Gender(this.value, this.label, this.icon);
}

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final UserRole role;
  final UserStatus status;
  final String? pin;
  final String? profilePhoto;
  final String? address;
  final String? city;
  final String? region;
  final String? garageId;
  final String? garageName;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final int? vehicleYear;
  final DriverStatus? driverStatus;
  final Gender? gender;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    this.status = UserStatus.active,
    this.pin,
    this.profilePhoto,
    this.address,
    this.city,
    this.region,
    this.garageId,
    this.garageName,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleYear,
    this.driverStatus,
    this.gender,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      role: json['role'] != null ? UserRole.fromString(json['role'].toString()) : UserRole.client,
      status: json['status'] != null 
          ? UserStatus.values.firstWhere(
              (e) => e.value == json['status'].toString(),
              orElse: () => UserStatus.active,
            )
          : UserStatus.active,
      pin: json['pin']?.toString(),
      profilePhoto: json['profilePhoto']?.toString() ?? json['profile_photo']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      garageId: json['garageId']?.toString() ?? json['garage_id']?.toString(),
      garageName: json['garageName']?.toString() ?? json['garage_name']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString() ?? json['vehicle_plate']?.toString(),
      vehicleModel: json['vehicleModel']?.toString() ?? json['vehicle_model']?.toString(),
      vehicleColor: json['vehicleColor']?.toString() ?? json['vehicle_color']?.toString(),
      vehicleYear: json['vehicleYear'] != null 
          ? int.tryParse(json['vehicleYear'].toString()) 
          : json['vehicle_year'] != null 
              ? int.tryParse(json['vehicle_year'].toString())
              : null,
      driverStatus: json['driverStatus'] != null 
          ? DriverStatus.values.firstWhere(
              (e) => e.value == json['driverStatus'].toString(),
              orElse: () => DriverStatus.offline,
            )
          : json['driver_status'] != null
              ? DriverStatus.values.firstWhere(
                  (e) => e.value == json['driver_status'].toString(),
                  orElse: () => DriverStatus.offline,
                )
              : null,
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.value == json['gender'].toString(),
              orElse: () => Gender.other,
            )
          : null,
      isEmailVerified: json['isEmailVerified'] ?? json['is_email_verified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? json['is_phone_verified'] ?? false,
      createdAt: parseDateTime(json['createdAt']) ?? parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']) ?? parseDateTime(json['updated_at']),
      lastLogin: parseDateTime(json['lastLogin']) ?? parseDateTime(json['last_login']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role.value,
    'status': status.value,
    'pin': pin,
    'profilePhoto': profilePhoto,
    'address': address,
    'city': city,
    'region': region,
    'garageId': garageId,
    'garageName': garageName,
    'vehiclePlate': vehiclePlate,
    'vehicleModel': vehicleModel,
    'vehicleColor': vehicleColor,
    'vehicleYear': vehicleYear,
    'driverStatus': driverStatus?.value,
    'gender': gender?.value,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
  };

  // Propriétés calculées
  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;
  bool get isDeleted => status == UserStatus.deleted;
  
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isDriver => role == UserRole.driver;
  bool get isClient => role == UserRole.client;
  
  bool get hasPin => pin != null && pin!.isNotEmpty;
  
  bool get canManageUsers => isSuperAdmin;
  bool get canManageGarages => isSuperAdmin;
  bool get canManageDrivers => isSuperAdmin || isAdmin;
  bool get canViewAllParcels => isSuperAdmin || isAdmin;
  bool get canDeliverParcels => isDriver;
  bool get canCreateParcels => isClient;
  
  bool get isDriverAvailable => isDriver && driverStatus == DriverStatus.available;
  bool get isDriverBusy => isDriver && driverStatus == DriverStatus.busy;
  bool get isDriverOffline => isDriver && driverStatus == DriverStatus.offline;
  
  String get displayName => fullName;
  
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
  
  String get formattedPhone {
    // Formater le téléphone pour l'affichage
    String rawPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (rawPhone.startsWith('221') && rawPhone.length > 9) {
      return '+${rawPhone.substring(0, 3)} ${rawPhone.substring(3, 6)} ${rawPhone.substring(6, 8)} ${rawPhone.substring(8, 10)}';
    }
    if (rawPhone.startsWith('77') && rawPhone.length == 9) {
      return '+221 $rawPhone';
    }
    return phone;
  }

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    UserRole? role,
    UserStatus? status,
    String? pin,
    String? profilePhoto,
    String? address,
    String? city,
    String? region,
    String? garageId,
    String? garageName,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleColor,
    int? vehicleYear,
    DriverStatus? driverStatus,
    Gender? gender,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      pin: pin ?? this.pin,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      garageId: garageId ?? this.garageId,
      garageName: garageName ?? this.garageName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      driverStatus: driverStatus ?? this.driverStatus,
      gender: gender ?? this.gender,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
  
  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: ${role.value})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}