import 'package:hive/hive.dart';

part 'User.g.dart'; // File yang akan digenerate oleh Hive

@HiveType(typeId: 1) // typeId harus unik untuk setiap model
class User extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String nama;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String alamat;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  DateTime? updatedAt;

  User({
    required this.username,
    this.nama = '',
    this.email = '',
    this.phone = '',
    this.alamat = '',
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for JSON serialization if needed
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'nama': nama,
      'email': email,
      'phone': phone,
      'alamat': alamat,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      alamat: map['alamat'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  // Copy with method for updating specific fields
  User copyWith({
    String? username,
    String? nama,
    String? email,
    String? phone,
    String? alamat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      username: username ?? this.username,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alamat: alamat ?? this.alamat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(username: $username, nama: $nama, email: $email, phone: $phone, alamat: $alamat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
        other.username == username &&
        other.nama == nama &&
        other.email == email &&
        other.phone == phone &&
        other.alamat == alamat;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        nama.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        alamat.hashCode;
  }
}