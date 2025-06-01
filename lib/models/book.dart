import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'dart:math';

part 'book.g.dart';

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
  DateTime startDate;

  @HiveField(12)
  DateTime endDate;

  @HiveField(13)
  DateTime bookingDate;

  @HiveField(14)
  DateTime? createdAt;

  @HiveField(15)
  String status; // 'pending', 'confirmed', 'active', 'completed', 'cancelled'

  @HiveField(16)
  String paymentStatus; // 'unpaid', 'dp', 'paid', 'refunded'

  @HiveField(17)
  double paidAmount;

  @HiveField(18)
  DateTime? paymentDate;

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
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0.0,
    this.paymentDate,
  });

  // Business Logic Methods
  
  /// Validasi apakah booking bisa dikonfirmasi
  bool canBeConfirmed() {
    return status == 'pending' && (paymentStatus == 'dp' || paymentStatus == 'paid');
  }
  
  /// Validasi apakah booking bisa dimulai (aktif)
  bool canBeActivated() {
    return status == 'confirmed' && DateTime.now().isAfter(startDate.subtract(Duration(hours: 1)));
  }
  
  /// **PERBAIKAN: Booking bisa diselesaikan jika sudah bayar lunas (tidak harus aktif)**
  bool canBeCompleted() {
    return (status == 'active' || status == 'confirmed') && paymentStatus == 'paid';
  }
  
  /// **PERBAIKAN: Booking bisa dibatalkan hanya jika belum aktif**
  bool canBeCancelled() {
    return ['pending', 'confirmed'].contains(status);
  }
  
  /// **PERBAIKAN: Booking bisa dihapus hanya jika sudah selesai atau dibatalkan**
  bool canBeDeleted() {
    return ['completed', 'cancelled'].contains(status);
  }
  
  /// Validasi apakah pembayaran bisa diproses
  bool canProcessPayment() {
    return !['cancelled', 'completed'].contains(status) && paymentStatus != 'paid';
  }
  
  /// Cek apakah rental sudah berakhir berdasarkan tanggal
  bool isRentalExpired() {
    return DateTime.now().isAfter(endDate);
  }
  
  /// **PERBAIKAN: Update payment dengan validasi yang lebih robust**
  Book updatePayment(String newPaymentStatus, double amount) {
    if (!canProcessPayment()) {
      throw Exception('Tidak dapat memproses pembayaran untuk booking yang ${getStatusText()}');
    }
    
    double newPaidAmount = paidAmount;
    DateTime? newPaymentDate = paymentDate;
    String finalPaymentStatus = newPaymentStatus;
    
    switch (newPaymentStatus) {
      case 'dp':
        // Validasi DP minimal 50% dari total harga
        if (amount < totalPrice * 0.5) {
          throw Exception('Jumlah DP minimal 50% dari total harga (${formatCurrency(totalPrice * 0.5)})');
        }
        
        // Validasi tidak boleh bayar DP jika sudah ada pembayaran sebelumnya
        if (paidAmount > 0) {
          throw Exception('Tidak dapat membayar DP karena sudah ada pembayaran sebelumnya');
        }
        
        newPaidAmount = amount;
        newPaymentDate = DateTime.now();
        break;
        
      case 'paid':
        // **PERBAIKAN: Untuk pembayaran lunas pertama kali**
        if (paidAmount == 0) {
          // Pembayaran lunas langsung tanpa DP
          if (amount < totalPrice) {
            throw Exception('Jumlah pembayaran kurang dari total harga (${formatCurrency(totalPrice)})');
          }
          newPaidAmount = totalPrice;
        } else {
          // **PERBAIKAN: Jika sudah ada DP, ini adalah pembayaran sisa**
          // Validasi bahwa amount sesuai dengan sisa yang harus dibayar
          double expectedRemainingAmount = totalPrice - paidAmount;
          if ((amount - expectedRemainingAmount) > 0.01) {
            throw Exception('Jumlah pembayaran sisa harus ${formatCurrency(expectedRemainingAmount)}');
          }
          newPaidAmount = totalPrice;
        }
        
        newPaymentDate = DateTime.now();
        finalPaymentStatus = 'paid';
        break;
        
      case 'unpaid':
        newPaidAmount = 0.0;
        newPaymentDate = null;
        break;
        
      default:
        throw Exception('Status pembayaran tidak valid: $newPaymentStatus');
    }
    
    return copyWith(
      paymentStatus: finalPaymentStatus,
      paidAmount: newPaidAmount,
      paymentDate: newPaymentDate,
    );
  }
  
  /// **PERBAIKAN: Method khusus untuk pembayaran sisa yang lebih simple**
  Book payRemainingAmount() {
    if (!canProcessPayment()) {
      throw Exception('Tidak dapat memproses pembayaran untuk booking yang ${getStatusText()}');
    }
    
    if (remainingAmount <= 0) {
      throw Exception('Tidak ada sisa pembayaran yang perlu dibayar');
    }
    
    // **SIMPLE: Langsung set ke lunas tanpa validasi amount**
    return copyWith(
      paymentStatus: 'paid',
      paidAmount: totalPrice,
      paymentDate: DateTime.now(),
    );
  }
  
  /// **PERBAIKAN: Update status booking dengan auto-confirm logic**
  Book updateStatus(String newStatus) {
    switch (newStatus) {
      case 'confirmed':
        if (!canBeConfirmed()) {
          throw Exception('Booking tidak dapat dikonfirmasi. Harus bayar DP atau lunas terlebih dahulu.');
        }
        break;
      case 'active':
        if (!canBeActivated()) {
          throw Exception('Booking tidak dapat diaktifkan. Pastikan sudah dikonfirmasi dan sudah waktunya rental.');
        }
        break;
      case 'completed':
        if (!canBeCompleted()) {
          throw Exception('Booking tidak dapat diselesaikan. Pastikan sudah bayar lunas.');
        }
        break;
      case 'cancelled':
        if (!canBeCancelled()) {
          throw Exception('Booking tidak dapat dibatalkan. Booking sudah ${getStatusText()}.');
        }
        // **PERBAIKAN: Refund logic yang lebih baik**
        if (paidAmount > 0) {
          return copyWith(
            status: newStatus,
            paymentStatus: 'refunded',
          );
        }
        break;
    }
    
    return copyWith(status: newStatus);
  }

  /// **BARU: Method untuk auto-confirm setelah pembayaran**
  Book autoConfirmIfPaid() {
    if (status == 'pending' && (paymentStatus == 'dp' || paymentStatus == 'paid')) {
      return copyWith(status: 'confirmed');
    }
    return this;
  }

  // Helper Methods
  String get formattedTotalPrice {
    return formatCurrency(totalPrice);
  }

  String get formattedPaidAmount {
    return formatCurrency(paidAmount);
  }

  double get remainingAmount {
    return totalPrice - paidAmount;
  }

  String get formattedRemainingAmount {
    return formatCurrency(remainingAmount);
  }

  /// **PERBAIKAN: Helper method untuk format currency dengan import math**
  String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// **BARU: Method untuk menghitung jumlah refund**
  double get refundAmount {
    if (status == 'cancelled' && paymentStatus == 'refunded') {
      // Refund 100% jika dibatalkan sebelum rental dimulai
      if (DateTime.now().isBefore(startDate)) {
        return paidAmount;
      }
      // Refund 50% jika dibatalkan setelah rental dimulai
      return paidAmount * 0.5;
    }
    return 0.0;
  }

  String get formattedRefundAmount {
    return formatCurrency(refundAmount);
  }

  String get dateRange {
    return '$formattedStartDate - $formattedEndDate';
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

  // Status checks
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isUnpaid => paymentStatus == 'unpaid';
  bool get isDP => paymentStatus == 'dp';
  bool get isPaid => paymentStatus == 'paid';
  bool get isRefunded => paymentStatus == 'refunded';

  String getStatusText() {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'active':
        return 'Sedang Berjalan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Unknown';
    }
  }

  String getPaymentStatusText() {
    switch (paymentStatus) {
      case 'unpaid':
        return 'Belum Bayar';
      case 'dp':
        return 'DP (50%)';
      case 'paid':
        return 'Lunas';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return 'Unknown';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color getPaymentStatusColor() {
    switch (paymentStatus) {
      case 'unpaid':
        return Colors.red;
      case 'dp':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// **PERBAIKAN: Get available actions dengan logic yang benar**
  List<String> getAvailableActions() {
    List<String> actions = [];
    
    if (canBeConfirmed()) actions.add('confirm');
    if (canBeActivated()) actions.add('activate');
    if (canBeCompleted()) actions.add('complete');
    if (canBeCancelled()) actions.add('cancel');
    if (canProcessPayment()) actions.add('payment');
    
    return actions;
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

  // Convert to Map for JSON serialization
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
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      paymentDate: map['paymentDate'] != null 
          ? DateTime.parse(map['paymentDate']) 
          : null,
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, carName: $carName, userName: $userName, status: $status, paymentStatus: $paymentStatus, paidAmount: $paidAmount)';
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