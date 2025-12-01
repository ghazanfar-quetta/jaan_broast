class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isEmailVerified;
  final UserAddress? address;
  final UserAppData? appData;
  final UserDeliveryPreferences? deliveryPreferences;
  final DateTime? createdAt;
  final DateTime? lastSignedIn;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.isAnonymous = false,
    this.isEmailVerified = false,
    this.address,
    this.appData,
    this.deliveryPreferences,
    this.createdAt,
    this.lastSignedIn,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      address: data['address'] != null
          ? UserAddress.fromMap(data['address'] as Map<String, dynamic>)
          : null,
      appData: data['appData'] != null
          ? UserAppData.fromMap(data['appData'] as Map<String, dynamic>)
          : null,
      deliveryPreferences: data['deliveryPreferences'] != null
          ? UserDeliveryPreferences.fromMap(
              data['deliveryPreferences'] as Map<String, dynamic>,
            )
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      lastSignedIn: data['lastSignedIn'] != null
          ? DateTime.parse(data['lastSignedIn'] as String)
          : null,
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'isEmailVerified': isEmailVerified,
      'address': address?.toMap(),
      'appData': appData?.toMap(),
      'deliveryPreferences': deliveryPreferences?.toMap(),
      'createdAt': createdAt?.toIso8601String(),
      'lastSignedIn': lastSignedIn?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    UserAddress? address,
    UserDeliveryPreferences? deliveryPreferences,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous,
      isEmailVerified: isEmailVerified,
      address: address ?? this.address,
      appData: appData,
      deliveryPreferences: deliveryPreferences ?? this.deliveryPreferences,
      createdAt: createdAt,
      lastSignedIn: lastSignedIn,
    );
  }
}

class UserAddress {
  final String? addressType;
  final Coordinates? coordinates;
  final String? fullAddress;
  final bool? isAutoLocation;
  final String? landmark;
  final String? streetNumber;
  final String? unitNumber;

  UserAddress({
    this.addressType,
    this.coordinates,
    this.fullAddress,
    this.isAutoLocation,
    this.landmark,
    this.streetNumber,
    this.unitNumber,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      addressType: map['addressType'] as String?,
      coordinates: map['coordinates'] != null
          ? Coordinates.fromMap(map['coordinates'] as Map<String, dynamic>)
          : null,
      fullAddress: map['fullAddress'] as String?,
      isAutoLocation: map['isAutoLocation'] as bool?,
      landmark: map['landmark'] as String?,
      streetNumber: map['streetNumber'] as String?,
      unitNumber: map['unitNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressType': addressType,
      'coordinates': coordinates?.toMap(),
      'fullAddress': fullAddress,
      'isAutoLocation': isAutoLocation,
      'landmark': landmark,
      'streetNumber': streetNumber,
      'unitNumber': unitNumber,
    };
  }

  UserAddress copyWith({
    String? addressType,
    Coordinates? coordinates,
    String? fullAddress,
    bool? isAutoLocation,
    String? landmark,
    String? streetNumber,
    String? unitNumber,
  }) {
    return UserAddress(
      addressType: addressType ?? this.addressType,
      coordinates: coordinates ?? this.coordinates,
      fullAddress: fullAddress ?? this.fullAddress,
      isAutoLocation: isAutoLocation ?? this.isAutoLocation,
      landmark: landmark ?? this.landmark,
      streetNumber: streetNumber ?? this.streetNumber,
      unitNumber: unitNumber ?? this.unitNumber,
    );
  }
}

class Coordinates {
  final double? latitude;
  final double? longitude;

  Coordinates({this.latitude, this.longitude});

  factory Coordinates.fromMap(Map<String, dynamic> map) {
    return Coordinates(
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class UserAppData {
  final String? accountCreatedAt;
  final bool? isFirstLoginCompleted;
  final String? lastUpdated;
  final bool? locationSetupCompleted;

  UserAppData({
    this.accountCreatedAt,
    this.isFirstLoginCompleted,
    this.lastUpdated,
    this.locationSetupCompleted,
  });

  factory UserAppData.fromMap(Map<String, dynamic> map) {
    return UserAppData(
      accountCreatedAt: map['accountCreatedAt'] as String?,
      isFirstLoginCompleted: map['isFirstLoginCompleted'] as bool?,
      lastUpdated: map['lastUpdated'] as String?,
      locationSetupCompleted: map['locationSetupCompleted'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountCreatedAt': accountCreatedAt,
      'isFirstLoginCompleted': isFirstLoginCompleted,
      'lastUpdated': lastUpdated,
      'locationSetupCompleted': locationSetupCompleted,
    };
  }
}

class UserDeliveryPreferences {
  final bool? contactlessDelivery;
  final String? deliveryInstructions;
  final bool? saveAddressForFuture;

  UserDeliveryPreferences({
    this.contactlessDelivery,
    this.deliveryInstructions,
    this.saveAddressForFuture,
  });

  factory UserDeliveryPreferences.fromMap(Map<String, dynamic> map) {
    return UserDeliveryPreferences(
      contactlessDelivery: map['contactlessDelivery'] as bool?,
      deliveryInstructions: map['deliveryInstructions'] as String?,
      saveAddressForFuture: map['saveAddressForFuture'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactlessDelivery': contactlessDelivery,
      'deliveryInstructions': deliveryInstructions,
      'saveAddressForFuture': saveAddressForFuture,
    };
  }

  UserDeliveryPreferences copyWith({
    bool? contactlessDelivery,
    String? deliveryInstructions,
    bool? saveAddressForFuture,
  }) {
    return UserDeliveryPreferences(
      contactlessDelivery: contactlessDelivery ?? this.contactlessDelivery,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      saveAddressForFuture: saveAddressForFuture ?? this.saveAddressForFuture,
    );
  }
}
