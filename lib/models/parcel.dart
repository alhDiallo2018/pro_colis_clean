// mobile/lib/models/parcel.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import 'payment.dart';

enum ParcelStatus {
  pending('pending', 'En attente', Colors.orange),
  confirmed('confirmed', 'Confirmé', Colors.blue),
  pickedUp('picked_up', 'Ramassé', Colors.purple),
  inTransit('in_transit', 'En transit', Colors.indigo),
  arrived('arrived', 'Arrivé', Colors.teal),
  outForDelivery('out_for_delivery', 'En livraison', Colors.lightBlue),
  delivered('delivered', 'Livré', Colors.green),
  cancelled('cancelled', 'Annulé', Colors.red);

  final String value;
  final String label;
  final Color color;
  const ParcelStatus(this.value, this.label, this.color);

  static ParcelStatus fromString(String value) {
    return ParcelStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParcelStatus.pending,
    );
  }
}

enum ParcelType {
  document('document', 'Documents', Icons.description),
  package('package', 'Colis standard', Icons.inventory),
  fragile('fragile', 'Fragile', Icons.warning),
  perishable('perishable', 'Périssable', Icons.food_bank),
  valuable('valuable', 'Valeur', Icons.attach_money);

  final String value;
  final String label;
  final IconData icon;
  const ParcelType(this.value, this.label, this.icon);

  static ParcelType fromString(String value) {
    return ParcelType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParcelType.package,
    );
  }
}

class Parcel {
  final String id;
  final String trackingNumber;
  
  // Expéditeur (client réel)
  final String senderId;
  final String senderName;
  final String senderPhone;
  final String? senderEmail;
  
  // Destinataire
  final String receiverName;
  final String receiverPhone;
  final String? receiverEmail;
  final String? receiverAddress;
  
  // Détails du colis
  final String description;
  final double weight;
  final double? length;
  final double? width;
  final double? height;
  final ParcelType type;
  final ParcelStatus status;
  
  // Trajet
  final String departureGarageId;
  final String departureGarageName;
  final String? arrivalGarageId;
  final String? arrivalGarageName;
  
  // Chauffeur
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  
  // Prix et options
  final double? price;
  final double? deliveryFees;
  final double? totalAmount;
  final bool isInsured;
  final double? insuranceAmount;
  final bool isUrgent;
  final double? urgentFee;
  
  // Paiement
  final PaymentMethod? paymentMethod;
  final String? paymentPhoneNumber;
  final String? paymentStatus;
  
  // Médias
  final List<String> photoUrls;
  final List<String> videoUrls;
  final String? signatureUrl;
  
  // Notes
  final String? notes;
  
  // Dates
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final DateTime? estimatedDeliveryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Traçabilité
  final String? createdBy;
  final String? createdByName;
  
  // Annulation
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  
  // Événements
  final List<ParcelEvent> events;

  Parcel({
    required this.id,
    required this.trackingNumber,
    required this.senderName,
    required this.senderPhone,
    this.senderId = '',
    this.senderEmail,
    required this.receiverName,
    required this.receiverPhone,
    this.receiverEmail,
    this.receiverAddress,
    required this.description,
    required this.weight,
    this.length,
    this.width,
    this.height,
    required this.type,
    required this.status,
    required this.departureGarageId,
    required this.departureGarageName,
    this.arrivalGarageId,
    this.arrivalGarageName,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.price,
    this.deliveryFees,
    this.totalAmount,
    this.isInsured = false,
    this.insuranceAmount,
    this.isUrgent = false,
    this.urgentFee,
    this.paymentMethod,
    this.paymentPhoneNumber,
    this.paymentStatus,
    this.photoUrls = const [],
    this.videoUrls = const [],
    this.signatureUrl,
    this.notes,
    this.pickupDate,
    this.deliveryDate,
    this.estimatedDeliveryDate,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.createdByName,
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
    this.events = const [],
  });

  factory Parcel.fromMinimalJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id']?.toString() ?? '',
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderPhone: json['senderPhone']?.toString() ?? '',
      receiverName: json['receiverName']?.toString() ?? '',
      receiverPhone: json['receiverPhone']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      type: json['type'] != null ? ParcelType.fromString(json['type'].toString()) : ParcelType.package,
      status: json['status'] != null ? ParcelStatus.fromString(json['status'].toString()) : ParcelStatus.pending,
      departureGarageId: json['departureGarageId']?.toString() ?? '',
      departureGarageName: json['departureGarageName']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
    );
  }

  factory Parcel.fromJson(Map<String, dynamic> json) {
    String? parseString(dynamic value) => value?.toString();
    double? parseDouble(dynamic value) => value != null ? (value is double ? value : double.tryParse(value.toString())) : null;
    DateTime? parseDateTime(dynamic value) => value != null ? DateTime.tryParse(value.toString()) : null;
    
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) {
        if (value.isEmpty || value == '[]') return [];
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (e) {
          return [];
        }
      }
      return [];
    }
    
    // Récupérer les événements
    List<ParcelEvent> events = [];
    if (json['events'] != null && json['events'] is List) {
      events = (json['events'] as List).map((e) => ParcelEvent.fromJson(e as Map<String, dynamic>)).toList();
    }

    return Parcel(
      id: parseString(json['id']) ?? '',
      trackingNumber: parseString(json['trackingNumber']) ?? '',
      senderId: parseString(json['senderId']) ?? '',
      senderName: parseString(json['senderName']) ?? '',
      senderPhone: parseString(json['senderPhone']) ?? '',
      senderEmail: parseString(json['senderEmail']),
      receiverName: parseString(json['receiverName']) ?? '',
      receiverPhone: parseString(json['receiverPhone']) ?? '',
      receiverEmail: parseString(json['receiverEmail']),
      receiverAddress: parseString(json['receiverAddress']),
      description: parseString(json['description']) ?? '',
      weight: parseDouble(json['weight']) ?? 0,
      length: parseDouble(json['length']),
      width: parseDouble(json['width']),
      height: parseDouble(json['height']),
      type: json['type'] != null ? ParcelType.fromString(parseString(json['type'])!) : ParcelType.package,
      status: json['status'] != null ? ParcelStatus.fromString(parseString(json['status'])!) : ParcelStatus.pending,
      departureGarageId: parseString(json['departureGarageId']) ?? '',
      departureGarageName: parseString(json['departureGarageName']) ?? '',
      arrivalGarageId: parseString(json['arrivalGarageId']),
      arrivalGarageName: parseString(json['arrivalGarageName']),
      driverId: parseString(json['driverId']),
      driverName: parseString(json['driverName']),
      driverPhone: parseString(json['driverPhone']),
      price: parseDouble(json['price']),
      deliveryFees: parseDouble(json['deliveryFees']),
      totalAmount: parseDouble(json['totalAmount']),
      isInsured: json['isInsured'] ?? false,
      insuranceAmount: parseDouble(json['insuranceAmount']),
      isUrgent: json['isUrgent'] ?? false,
      urgentFee: parseDouble(json['urgentFee']),
      paymentMethod: json['paymentMethod'] != null ? PaymentMethod.fromString(parseString(json['paymentMethod'])!) : null,
      paymentPhoneNumber: parseString(json['paymentPhoneNumber']),
      paymentStatus: parseString(json['paymentStatus']),
      photoUrls: parseList(json['photoUrls']),
      videoUrls: parseList(json['videoUrls']),
      signatureUrl: parseString(json['signatureUrl']),
      notes: parseString(json['notes']),
      pickupDate: parseDateTime(json['pickupDate']),
      deliveryDate: parseDateTime(json['deliveryDate']),
      estimatedDeliveryDate: parseDateTime(json['estimatedDeliveryDate']),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']),
      createdBy: parseString(json['createdBy']),
      createdByName: parseString(json['createdByName']),
      cancelledBy: parseString(json['cancelledBy']),
      cancellationReason: parseString(json['cancellationReason']),
      cancelledAt: parseDateTime(json['cancelledAt']),
      events: events,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackingNumber': trackingNumber,
    'senderId': senderId,
    'senderName': senderName,
    'senderPhone': senderPhone,
    'senderEmail': senderEmail,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'receiverEmail': receiverEmail,
    'receiverAddress': receiverAddress,
    'description': description,
    'weight': weight,
    'length': length,
    'width': width,
    'height': height,
    'type': type.value,
    'status': status.value,
    'departureGarageId': departureGarageId,
    'departureGarageName': departureGarageName,
    'arrivalGarageId': arrivalGarageId,
    'arrivalGarageName': arrivalGarageName,
    'driverId': driverId,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'price': price,
    'deliveryFees': deliveryFees,
    'totalAmount': totalAmount,
    'isInsured': isInsured,
    'insuranceAmount': insuranceAmount,
    'isUrgent': isUrgent,
    'urgentFee': urgentFee,
    'paymentMethod': paymentMethod?.value,
    'paymentPhoneNumber': paymentPhoneNumber,
    'paymentStatus': paymentStatus,
    'photoUrls': photoUrls,
    'videoUrls': videoUrls,
    'signatureUrl': signatureUrl,
    'notes': notes,
    'pickupDate': pickupDate?.toIso8601String(),
    'deliveryDate': deliveryDate?.toIso8601String(),
    'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'createdBy': createdBy,
    'createdByName': createdByName,
    'cancelledBy': cancelledBy,
    'cancellationReason': cancellationReason,
    'cancelledAt': cancelledAt?.toIso8601String(),
    'events': events.map((e) => e.toJson()).toList(),
  };

  // ==================== PROPRIÉTÉS CALCULÉES ====================
  
  bool get isPending => status == ParcelStatus.pending;
  bool get isConfirmed => status == ParcelStatus.confirmed;
  bool get isPickedUp => status == ParcelStatus.pickedUp;
  bool get isInTransit => status == ParcelStatus.inTransit;
  bool get isArrived => status == ParcelStatus.arrived;
  bool get isOutForDelivery => status == ParcelStatus.outForDelivery;
  bool get isDelivered => status == ParcelStatus.delivered;
  bool get isCancelled => status == ParcelStatus.cancelled;
  
  bool get isInProgress => status == ParcelStatus.confirmed || 
                            status == ParcelStatus.pickedUp || 
                            status == ParcelStatus.inTransit || 
                            status == ParcelStatus.arrived || 
                            status == ParcelStatus.outForDelivery;
  
  bool get isFinished => status == ParcelStatus.delivered || status == ParcelStatus.cancelled;
  
  bool get hasDriver => driverId != null && driverId!.isNotEmpty;
  bool get hasClient => senderId.isNotEmpty;
  
  bool get isPaid => paymentStatus == 'completed' || paymentStatus == 'paid';
  
  String get formattedWeight => '${weight.toStringAsFixed(1)} kg';
  
  String get formattedPrice => '${price?.toStringAsFixed(0) ?? 0} FCFA';
  
  String get formattedTotal => '${totalAmount?.toStringAsFixed(0) ?? price?.toStringAsFixed(0) ?? 0} FCFA';
  
  String get formattedDeliveryFees => '${deliveryFees?.toStringAsFixed(0) ?? 0} FCFA';
  
  double get volume {
    if (length == null || width == null || height == null) return 0;
    return length! * width! * height! / 1000000;
  }
  
  String get formattedVolume => '${volume.toStringAsFixed(2)} m³';
  
  String get formattedDate => '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  
  String get formattedTime => '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  
  String get formattedDateTime => '$formattedDate à $formattedTime';
  
  String get formattedDeliveryDate => deliveryDate != null 
      ? '${deliveryDate!.day}/${deliveryDate!.month}/${deliveryDate!.year}' 
      : 'Non livré';
  
  String get statusIcon {
    switch (status) {
      case ParcelStatus.pending:
        return '⏳';
      case ParcelStatus.confirmed:
        return '✅';
      case ParcelStatus.pickedUp:
        return '📦';
      case ParcelStatus.inTransit:
        return '🚚';
      case ParcelStatus.arrived:
        return '📍';
      case ParcelStatus.outForDelivery:
        return '🚛';
      case ParcelStatus.delivered:
        return '🎉';
      case ParcelStatus.cancelled:
        return '❌';
    }
  }

  Parcel copyWith({
    String? id,
    String? trackingNumber,
    String? senderId,
    String? senderName,
    String? senderPhone,
    String? senderEmail,
    String? receiverName,
    String? receiverPhone,
    String? receiverEmail,
    String? receiverAddress,
    String? description,
    double? weight,
    double? length,
    double? width,
    double? height,
    ParcelType? type,
    ParcelStatus? status,
    String? departureGarageId,
    String? departureGarageName,
    String? arrivalGarageId,
    String? arrivalGarageName,
    String? driverId,
    String? driverName,
    String? driverPhone,
    double? price,
    double? deliveryFees,
    double? totalAmount,
    bool? isInsured,
    double? insuranceAmount,
    bool? isUrgent,
    double? urgentFee,
    PaymentMethod? paymentMethod,
    String? paymentPhoneNumber,
    String? paymentStatus,
    List<String>? photoUrls,
    List<String>? videoUrls,
    String? signatureUrl,
    String? notes,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    DateTime? estimatedDeliveryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? createdByName,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? cancelledAt,
    List<ParcelEvent>? events,
  }) {
    return Parcel(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      type: type ?? this.type,
      status: status ?? this.status,
      departureGarageId: departureGarageId ?? this.departureGarageId,
      departureGarageName: departureGarageName ?? this.departureGarageName,
      arrivalGarageId: arrivalGarageId ?? this.arrivalGarageId,
      arrivalGarageName: arrivalGarageName ?? this.arrivalGarageName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      price: price ?? this.price,
      deliveryFees: deliveryFees ?? this.deliveryFees,
      totalAmount: totalAmount ?? this.totalAmount,
      isInsured: isInsured ?? this.isInsured,
      insuranceAmount: insuranceAmount ?? this.insuranceAmount,
      isUrgent: isUrgent ?? this.isUrgent,
      urgentFee: urgentFee ?? this.urgentFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentPhoneNumber: paymentPhoneNumber ?? this.paymentPhoneNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      notes: notes ?? this.notes,
      pickupDate: pickupDate ?? this.pickupDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      events: events ?? this.events,
    );
  }
}

class ParcelEvent {
  final String id;
  final String parcelId;
  final ParcelStatus status;
  final String description;
  final String? location;
  final String? locationLat;
  final String? locationLng;
  final String? userId;
  final String? userName;
  final String? userRole;
  final String? photoUrl;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ParcelEvent({
    required this.id,
    required this.parcelId,
    required this.status,
    required this.description,
    this.location,
    this.locationLat,
    this.locationLng,
    this.userId,
    this.userName,
    this.userRole,
    this.photoUrl,
    this.metadata = const {},
    required this.timestamp,
  });

  factory ParcelEvent.fromJson(Map<String, dynamic> json) {
    // Gestion sécurisée du metadata
    Map<String, dynamic> metadata = {};
    if (json['metadata'] != null) {
      if (json['metadata'] is String) {
        try {
          metadata = jsonDecode(json['metadata']);
        } catch (e) {
          metadata = {};
        }
      } else if (json['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(json['metadata']);
      }
    }
    
    // Gestion sécurisée de la date
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ParcelEvent(
      id: json['id']?.toString() ?? '',
      parcelId: json['parcelId']?.toString() ?? json['parcel_id']?.toString() ?? '',
      status: json['status'] != null ? ParcelStatus.fromString(json['status'].toString()) : ParcelStatus.pending,
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString(),
      locationLat: json['locationLat']?.toString(),
      locationLng: json['locationLng']?.toString(),
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
      userRole: json['userRole']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      metadata: metadata,
      timestamp: parseDate(json['timestamp'] ?? json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'status': status.value,
    'description': description,
    'location': location,
    'locationLat': locationLat,
    'locationLng': locationLng,
    'userId': userId,
    'userName': userName,
    'userRole': userRole,
    'photoUrl': photoUrl,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };
  
  // Propriétés utiles
  String get formattedTime {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
  
  String get formattedDateTime {
    return '$formattedDate à $formattedTime';
  }
  
  // Récupérer une valeur du metadata
  T? getMetadata<T>(String key) {
    if (metadata.containsKey(key)) {
      return metadata[key] as T?;
    }
    return null;
  }
  
  bool get hasLocation => location != null && location!.isNotEmpty;
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasUser => userName != null && userName!.isNotEmpty;
}