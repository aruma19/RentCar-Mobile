import 'package:hive/hive.dart';
import 'package:flutter/material.dart'; // Tambah import ini untuk Colors

part 'book.g.dart'; // Nama file huruf kecil untuk konsistensi

@HiveType(typeId: 2) 
class Book extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String carId;

  @HiveField(2)
  String carName;

  @HiveField(3)
  String carMerk;

  @HiveField(4)
  String userName;

  @HiveField(5)
  String userId;

  @HiveField(6)
  int rentalDays;

  @HiveField(7)
  bool needDriver;

  @HiveField(8)
  double basePrice;

  @HiveField(9)
  double driverPrice;

  @HiveField(10)
  double totalPrice;

  @HiveField(11)
  DateTime startDate; // Tanggal mulai rental

  @HiveField(12)
  DateTime endDate; // Tanggal selesai rental

  @HiveField(13)
  DateTime bookingDate; // Tanggal booking dibuat

  @HiveField(14)
  DateTime? createdAt;

  @HiveField(15)
  String status; // 'active', 'completed', 'cancelled'

  @HiveField(16)
  String paymentStatus; // 'pending', 'dp', 'paid'

  @HiveField(17)
  double paidAmount; // Jumlah yang sudah dibayar

  @HiveField(18)
  DateTime? paymentDate; // Tanggal pelunasan

  Book({
    required this.id,
    required this.carId,
    required this.carName,
    required this.carMerk,
    required this.userName,
    required this.userId,
    required this.rentalDays,
    required this.needDriver,
    required this.basePrice,
    required this.driverPrice,
    required this.totalPrice,
    required this.startDate,
    required this.endDate,
    required this.bookingDate,
    this.createdAt,
    this.status = 'active',
    this.paymentStatus = 'pending',
    this.paidAmount = 0.0,
    this.paymentDate,
  });

  // Convert to Map for JSON serialization if needed
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'carName': carName,
      'carMerk': carMerk,
      'userName': userName,
      'userId': userId,
      'rentalDays': rentalDays,
      'needDriver': needDriver,
      'basePrice': basePrice,
      'driverPrice': driverPrice,
      'totalPrice': totalPrice,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'bookingDate': bookingDate.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'paymentDate': paymentDate?.toIso8601String(),
    };
  }

  // Create Book from Map
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      carId: map['carId'] ?? '',
      carName: map['carName'] ?? '',
      carMerk: map['carMerk'] ?? '',
      userName: map['userName'] ?? '',
      userId: map['userId'] ?? '',
      rentalDays: map['rentalDays'] ?? 0,
      needDriver: map['needDriver'] ?? false,
      basePrice: (map['basePrice'] ?? 0.0).toDouble(),
      driverPrice: (map['driverPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : DateTime.now(),
      endDate: map['endDate'] != null 
          ? DateTime.parse(map['endDate']) 
          : DateTime.now().add(Duration(days: 1)),
      bookingDate: map['bookingDate'] != null 
          ? DateTime.parse(map['bookingDate']) 
          : DateTime.now(),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : null,
      status: map['status'] ?? 'active',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      paymentDate: map['paymentDate'] != null 
          ? DateTime.parse(map['paymentDate']) 
          : null,
    );
  }

  // Copy with method for updating specific fields
  Book copyWith({
    String? id,
    String? carId,
    String? carName,
    String? carMerk,
    String? userName,
    String? userId,
    int? rentalDays,
    bool? needDriver,
    double? basePrice,
    double? driverPrice,
    double? totalPrice,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? bookingDate,
    DateTime? createdAt,
    String? status,
    String? paymentStatus,
    double? paidAmount,
    DateTime? paymentDate,
  }) {
    return Book(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      carName: carName ?? this.carName,
      carMerk: carMerk ?? this.carMerk,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      rentalDays: rentalDays ?? this.rentalDays,
      needDriver: needDriver ?? this.needDriver,
      basePrice: basePrice ?? this.basePrice,
      driverPrice: driverPrice ?? this.driverPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bookingDate: bookingDate ?? this.bookingDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  // Helper methods
  String get formattedTotalPrice {
    return 'Rp ${totalPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get formattedPaidAmount {
    return 'Rp ${paidAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  double get remainingAmount {
    return totalPrice - paidAmount;
  }

  String get formattedRemainingAmount {
    return 'Rp ${remainingAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get formattedStartDate {
    return '${startDate.day.toString().padLeft(2, '0')}/'
           '${startDate.month.toString().padLeft(2, '0')}/'
           '${startDate.year}';
  }

  String get formattedEndDate {
    return '${endDate.day.toString().padLeft(2, '0')}/'
           '${endDate.month.toString().padLeft(2, '0')}/'
           '${endDate.year}';
  }

  String get formattedBookingDate {
    return '${bookingDate.day.toString().padLeft(2, '0')}/'
           '${bookingDate.month.toString().padLeft(2, '0')}/'
           '${bookingDate.year}';
  }

  String get formattedPaymentDate {
    if (paymentDate == null) return '-';
    return '${paymentDate!.day.toString().padLeft(2, '0')}/'
           '${paymentDate!.month.toString().padLeft(2, '0')}/'
           '${paymentDate!.year}';
  }

  String get dateRange {
    return '$formattedStartDate - $formattedEndDate';
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isPending => paymentStatus == 'pending';
  bool get isDP => paymentStatus == 'dp';
  bool get isPaid => paymentStatus == 'paid';

  String get paymentStatusText {
    switch (paymentStatus) {
      case 'pending':
        return 'Belum Bayar';
      case 'dp':
        return 'DP';
      case 'paid':
        return 'Lunas';
      default:
        return 'Unknown';
    }
  }

  Color get paymentStatusColor {
    switch (paymentStatus) {
      case 'pending':
        return Colors.red;
      case 'dp':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() {
    return 'Book(id: $id, carName: $carName, userName: $userName, dateRange: $dateRange, totalPrice: $totalPrice, status: $status, paymentStatus: $paymentStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Book &&
        other.id == id &&
        other.carId == carId &&
        other.userName == userName &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        carId.hashCode ^
        userName.hashCode ^
        userId.hashCode;
  }
}