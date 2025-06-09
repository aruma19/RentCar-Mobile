// RentCar
import 'package:hive_flutter/hive_flutter.dart';
import '../models/User.dart';
import '../models/book.dart';

class HiveService {
  static const String _userBoxName = 'user_objects';
  static const String _passwordBoxName = 'users';
  static const String _bookingBoxName = 'bookings';
  static const String _favoritesBoxPrefix = 'favorites_';
  static const String _userDataBoxPrefix = 'user_data_';

  // Initialize Hive
  static Future<void> init() async {
    try {
      print('🚀 Initializing Hive...');
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserAdapter());
        print('✅ UserAdapter registered');
      }
      
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(BookAdapter());
        print('✅ BookAdapter registered');
      }

      // Open essential boxes
      await openEssentialBoxes();
      print('✅ Hive initialization completed');
    } catch (e) {
      print('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

  // Open essential boxes
  static Future<void> openEssentialBoxes() async {
    try {
      // Open password box (existing system)
      if (!Hive.isBoxOpen(_passwordBoxName)) {
        await Hive.openBox(_passwordBoxName);
        print('✅ Password box opened: $_passwordBoxName');
      }

      // Open user objects box
      if (!Hive.isBoxOpen(_userBoxName)) {
        await Hive.openBox<User>(_userBoxName);
        print('✅ User box opened: $_userBoxName');
      }

      // Open booking box
      if (!Hive.isBoxOpen(_bookingBoxName)) {
        await Hive.openBox<Book>(_bookingBoxName);
        print('✅ Booking box opened: $_bookingBoxName');
      }
    } catch (e) {
      print('❌ Error opening essential boxes: $e');
      rethrow;
    }
  }

  // User Box Operations
  static Future<Box<User>> getUserBox() async {
    if (!Hive.isBoxOpen(_userBoxName)) {
      print('📦 Opening user box: $_userBoxName');
      await Hive.openBox<User>(_userBoxName);
    }
    return Hive.box<User>(_userBoxName);
  }

  static Box<User> getUserBoxSync() {
    if (!Hive.isBoxOpen(_userBoxName)) {
      throw HiveError('User box is not open. Call HiveService.init() first.');
    }
    return Hive.box<User>(_userBoxName);
  }

  // Password Box Operations (existing system)
  static Box getPasswordBox() {
    if (!Hive.isBoxOpen(_passwordBoxName)) {
      throw HiveError('Password box is not open. Call HiveService.init() first.');
    }
    return Hive.box(_passwordBoxName);
  }

  // Booking Box Operations
  static Future<Box<Book>> getBookingBox() async {
    if (!Hive.isBoxOpen(_bookingBoxName)) {
      await Hive.openBox<Book>(_bookingBoxName);
    }
    return Hive.box<Book>(_bookingBoxName);
  }

  static Box<Book> getBookingBoxSync() {
    if (!Hive.isBoxOpen(_bookingBoxName)) {
      throw HiveError('Booking box is not open. Call HiveService.init() first.');
    }
    return Hive.box<Book>(_bookingBoxName);
  }

  // Enhanced Favorites Box Operations
  static Future<Box> getFavoritesBox(String username) async {
    final boxName = '$_favoritesBoxPrefix$username';
    try {
      if (!Hive.isBoxOpen(boxName)) {
        final box = await Hive.openBox(boxName);
        print('📦 Opened favorites box for user: $username');
        return box;
      }
      return Hive.box(boxName);
    } catch (e) {
      print('❌ Error opening favorites box for $username: $e');
      rethrow;
    }
  }

  static Future<Box> getUserDataBox(String username) async {
    final boxName = '$_userDataBoxPrefix$username';
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  // User CRUD Operations
  static Future<void> saveUser(User user) async {
    try {
      final box = await getUserBox();
      await box.put(user.username, user);
      print('✅ User saved: ${user.username}');
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }

  static Future<User?> getUser(String username) async {
    try {
      final box = await getUserBox();
      return box.get(username);
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  static Future<void> updateUser(User user) async {
    try {
      user.updatedAt = DateTime.now();
      await saveUser(user);
      print('✅ User updated: ${user.username}');
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String username) async {
    try {
      final box = await getUserBox();
      await box.delete(username);
      print('✅ User deleted: $username');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  static Future<List<User>> getAllUsers() async {
    try {
      final box = await getUserBox();
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  // Password Operations (existing system compatibility)
  static Future<void> savePassword(String username, String password) async {
    try {
      final box = getPasswordBox();
      await box.put(username, password);
      print('✅ Password saved for: $username');
    } catch (e) {
      print('❌ Error saving password: $e');
      rethrow;
    }
  }

  static String? getPassword(String username) {
    try {
      final box = getPasswordBox();
      return box.get(username);
    } catch (e) {
      print('❌ Error getting password: $e');
      return null;
    }
  }

  static bool passwordExists(String username) {
    try {
      final box = getPasswordBox();
      return box.containsKey(username);
    } catch (e) {
      print('❌ Error checking password existence: $e');
      return false;
    }
  }

  // ============================================================================
  // BOOKING OPERATIONS - DENGAN BUSINESS LOGIC VALIDATION
  // ============================================================================

  /// **PERBAIKAN: Menyimpan booking baru dengan auto-confirm logic**
  static Future<String> saveBooking(Book booking) async {
    try {
      final box = await getBookingBox();
      
      // Validate business logic before saving
      if (booking.paymentStatus == 'dp' && booking.paidAmount < booking.totalPrice * 0.5) {
        throw Exception('Jumlah DP harus minimal 50% dari total harga');
      }
      
      if (booking.paymentStatus == 'paid' && booking.paidAmount < booking.totalPrice) {
        throw Exception('Jumlah pembayaran kurang dari total harga');
      }
      
      // **BARU: Auto-confirm jika sudah bayar**
      final finalBooking = booking.autoConfirmIfPaid();
      
      await box.put(finalBooking.id, finalBooking);
      print('✅ Booking saved: ${finalBooking.id} for user: ${finalBooking.userId} - Status: ${finalBooking.status}');
      return finalBooking.id;
    } catch (e) {
      print('❌ Error saving booking: $e');
      rethrow;
    }
  }

  /// Update booking dengan validasi business logic
  static Future<void> updateBooking(Book booking) async {
    try {
      await saveBooking(booking);
      print('✅ Booking updated: ${booking.id}');
    } catch (e) {
      print('❌ Error updating booking: $e');
      rethrow;
    }
  }

  /// **PERBAIKAN: Update status booking dengan auto-confirm logic**
  static Future<Book> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final box = await getBookingBox();
      final booking = box.get(bookingId);
      
      if (booking == null) {
        throw Exception('Booking tidak ditemukan');
      }
      
      final updatedBooking = booking.updateStatus(newStatus);
      await box.put(bookingId, updatedBooking);
      
      print('✅ Booking status updated: $bookingId -> $newStatus');
      return updatedBooking;
    } catch (e) {
      print('❌ Error updating booking status: $e');
      rethrow;
    }
  }

  /// **PERBAIKAN: Update payment dengan auto-confirm dan improved logic**
  static Future<Book> updateBookingPayment(String bookingId, String newPaymentStatus, double amount) async {
    try {
      final box = await getBookingBox();
      final booking = box.get(bookingId);
      
      if (booking == null) {
        throw Exception('Booking tidak ditemukan');
      }
      
      Book updatedBooking;
      
      // **PERBAIKAN: Simplified logic**
      if (newPaymentStatus == 'paid' && booking.paidAmount > 0) {
        // Jika sudah ada pembayaran sebelumnya (DP), gunakan method payRemainingAmount
        updatedBooking = booking.payRemainingAmount();
        print('✅ Remaining payment completed for booking: $bookingId');
      } else {
        // Untuk pembayaran baru (DP atau lunas langsung)
        updatedBooking = booking.updatePayment(newPaymentStatus, amount);
        print('✅ New payment processed for booking: $bookingId -> $newPaymentStatus (${amount})');
      }
      
      // **BARU: Auto-confirm setelah pembayaran**
      final finalBooking = updatedBooking.autoConfirmIfPaid();
      
      await box.put(bookingId, finalBooking);
      
      print('✅ Final booking status: ${finalBooking.status} - Payment: ${finalBooking.paymentStatus}');
      return finalBooking;
    } catch (e) {
      print('❌ Error updating booking payment: $e');
      rethrow;
    }
  }

  /// **PERBAIKAN: Method khusus untuk pembayaran sisa dengan auto-confirm**
  static Future<Book> payBookingRemainingAmount(String bookingId) async {
    try {
      final box = await getBookingBox();
      final booking = box.get(bookingId);
      
      if (booking == null) {
        throw Exception('Booking tidak ditemukan');
      }
      
      if (booking.remainingAmount <= 0) {
        throw Exception('Tidak ada sisa pembayaran yang perlu dibayar');
      }
      
      final updatedBooking = booking.payRemainingAmount();
      
      // **BARU: Auto-confirm setelah pembayaran**
      final finalBooking = updatedBooking.autoConfirmIfPaid();
      
      await box.put(bookingId, finalBooking);
      
      print('✅ Remaining amount paid for booking: $bookingId - Status: ${finalBooking.status}');
      return finalBooking;
    } catch (e) {
      print('❌ Error paying remaining amount: $e');
      rethrow;
    }
  }

  /// **PERBAIKAN: Hapus booking hanya jika sudah selesai atau dibatalkan**
  static Future<void> deleteBooking(String bookingId) async {
    try {
      final box = await getBookingBox();
      final booking = box.get(bookingId);
      
      if (booking == null) {
        throw Exception('Booking tidak ditemukan');
      }
      
      if (!booking.canBeDeleted()) {
        throw Exception('Booking tidak dapat dihapus. Harus dibatalkan atau diselesaikan terlebih dahulu. Status saat ini: ${booking.getStatusText()}');
      }
      
      await box.delete(bookingId);
      print('✅ Booking deleted: $bookingId');
    } catch (e) {
      print('❌ Error deleting booking: $e');
      rethrow;
    }
  }

  /// Ambil booking berdasarkan ID
  static Future<Book?> getBooking(String bookingId) async {
    try {
      final box = await getBookingBox();
      return box.get(bookingId);
    } catch (e) {
      print('❌ Error getting booking: $e');
      return null;
    }
  }

  // ============================================================================
  // BOOKING QUERIES - DENGAN FILTER PER USER
  // ============================================================================

  /// Ambil SEMUA booking (untuk admin)
  static Future<List<Book>> getAllBookings() async {
    try {
      final box = await getBookingBox();
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting all bookings: $e');
      return [];
    }
  }

  /// **PENTING: Ambil booking berdasarkan USER ID - INI YANG DIPERLUKAN**
  static Future<List<Book>> getBookingsByUser(String userId) async {
    try {
      final box = await getBookingBox();
      final userBookings = box.values.where((booking) => booking.userId == userId).toList();
      
      // Sort by booking date (newest first)
      userBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      
      print('✅ Retrieved ${userBookings.length} bookings for user: $userId');
      return userBookings;
    } catch (e) {
      print('❌ Error getting bookings for user $userId: $e');
      return [];
    }
  }

  /// Ambil booking berdasarkan status untuk user tertentu
  static Future<List<Book>> getBookingsByUserAndStatus(String userId, String status) async {
    try {
      final userBookings = await getBookingsByUser(userId);
      return userBookings.where((booking) => booking.status == status).toList();
    } catch (e) {
      print('❌ Error getting bookings by status: $e');
      return [];
    }
  }

  /// Ambil booking aktif untuk user tertentu
  static Future<List<Book>> getActiveBookingsByUser(String userId) async {
    return getBookingsByUserAndStatus(userId, 'active');
  }

  /// Ambil booking pending untuk user tertentu
  static Future<List<Book>> getPendingBookingsByUser(String userId) async {
    return getBookingsByUserAndStatus(userId, 'pending');
  }

  /// Ambil booking completed untuk user tertentu
  static Future<List<Book>> getCompletedBookingsByUser(String userId) async {
    return getBookingsByUserAndStatus(userId, 'completed');
  }

  /// Ambil booking cancelled untuk user tertentu
  static Future<List<Book>> getCancelledBookingsByUser(String userId) async {
    return getBookingsByUserAndStatus(userId, 'cancelled');
  }

  /// Ambil booking berdasarkan payment status untuk user tertentu
  static Future<List<Book>> getBookingsByUserAndPaymentStatus(String userId, String paymentStatus) async {
    try {
      final userBookings = await getBookingsByUser(userId);
      return userBookings.where((booking) => booking.paymentStatus == paymentStatus).toList();
    } catch (e) {
      print('❌ Error getting bookings by payment status: $e');
      return [];
    }
  }

  /// Cek apakah user memiliki booking aktif untuk mobil tertentu
  static Future<bool> hasActiveBookingForCar(String userId, String carId) async {
    try {
      final userBookings = await getBookingsByUser(userId);
      return userBookings.any((booking) => 
        booking.carId == carId && 
        ['pending', 'confirmed', 'active'].contains(booking.status)
      );
    } catch (e) {
      print('❌ Error checking active booking for car: $e');
      return false;
    }
  }

  // ============================================================================
  // BOOKING STATISTICS PER USER
  // ============================================================================

  /// Statistik booking untuk user tertentu
  static Future<Map<String, int>> getBookingStatsByUser(String userId) async {
    try {
      final userBookings = await getBookingsByUser(userId);
      return {
        'total': userBookings.length,
        'pending': userBookings.where((b) => b.status == 'pending').length,
        'confirmed': userBookings.where((b) => b.status == 'confirmed').length,
        'active': userBookings.where((b) => b.status == 'active').length,
        'completed': userBookings.where((b) => b.status == 'completed').length,
        'cancelled': userBookings.where((b) => b.status == 'cancelled').length,
      };
    } catch (e) {
      print('❌ Error getting booking stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'active': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }

  /// **BARU: Statistik pembayaran dan refund untuk user tertentu**
  static Future<Map<String, dynamic>> getPaymentStatsByUser(String userId) async {
    try {
      final userBookings = await getBookingsByUser(userId);
      
      double totalSpent = 0;
      double totalPending = 0;
      double totalRefund = 0;
      int paidBookings = 0;
      int unpaidBookings = 0;
      int refundedBookings = 0;
      
      for (Book booking in userBookings) {
        if (booking.isCompleted && booking.isPaid) {
          totalSpent += booking.totalPrice;
          paidBookings++;
        } else if (!booking.isCancelled && booking.remainingAmount > 0) {
          totalPending += booking.remainingAmount;
          unpaidBookings++;
        }
        
        if (booking.isCancelled && booking.isRefunded) {
          totalRefund += booking.refundAmount;
          refundedBookings++;
        }
      }
      
      return {
        'total_spent': totalSpent,
        'total_pending': totalPending,
        'total_refund': totalRefund,
        'paid_bookings': paidBookings,
        'unpaid_bookings': unpaidBookings,
        'refunded_bookings': refundedBookings,
      };
    } catch (e) {
      print('❌ Error getting payment stats: $e');
      return {
        'total_spent': 0.0,
        'total_pending': 0.0,
        'total_refund': 0.0,
        'paid_bookings': 0,
        'unpaid_bookings': 0,
        'refunded_bookings': 0,
      };
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Generate unique booking ID
  static String generateBookingId() {
    final now = DateTime.now();
    return 'BK${now.millisecondsSinceEpoch}';
  }

  /// Auto-update expired bookings
  static Future<int> updateExpiredBookings() async {
    try {
      final box = await getBookingBox();
      final allBookings = box.values.toList();
      int updatedCount = 0;
      
      for (Book booking in allBookings) {
        if (booking.isActive && booking.isRentalExpired()) {
          try {
            final updatedBooking = booking.updateStatus('completed');
            await box.put(booking.id, updatedBooking);
            updatedCount++;
            print('✅ Auto-completed expired booking: ${booking.id}');
          } catch (e) {
            print('⚠️ Could not auto-complete booking ${booking.id}: $e');
          }
        }
      }
      
      return updatedCount;
    } catch (e) {
      print('❌ Error updating expired bookings: $e');
      return 0;
    }
  }

  // Enhanced Favorites Operations (unchanged)
  static Future<void> addToFavorites(String username, String carId, Map<String, dynamic> carData) async {
    try {
      final box = await getFavoritesBox(username);
      await box.put(carId, carData);
      print('✅ Added to favorites: $carId for user $username');
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  static Future<void> removeFromFavorites(String username, String carId) async {
    try {
      final box = await getFavoritesBox(username);
      await box.delete(carId);
      print('✅ Removed from favorites: $carId for user $username');
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  static Future<bool> isFavorite(String username, String carId) async {
    try {
      final box = await getFavoritesBox(username);
      return box.containsKey(carId);
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getFavorites(String username) async {
    try {
      final box = await getFavoritesBox(username);
      final List<Map<String, dynamic>> favorites = [];
      
      for (final key in box.keys) {
        try {
          final value = box.get(key);
          if (value is Map) {
            final Map<String, dynamic> carData = Map<String, dynamic>.from(value);
            favorites.add(carData);
          }
        } catch (e) {
          print('⚠️ Error parsing favorite $key for user $username: $e');
        }
      }
      
      return favorites;
    } catch (e) {
      print('❌ Error getting favorites: $e');
      return [];
    }
  }

  // Cleanup Operations
  static Future<void> closeAllBoxes() async {
    try {
      await Hive.close();
      print('✅ All Hive boxes closed');
    } catch (e) {
      print('❌ Error closing boxes: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      await Hive.deleteFromDisk();
      print('✅ All Hive data deleted from disk');
    } catch (e) {
      print('❌ Error clearing all data: $e');
    }
  }

  // Debug Methods
  static Future<void> printBookingsDebug(String userId) async {
    print('=== BOOKING DEBUG for user: $userId ===');
    
    try {
      final userBookings = await getBookingsByUser(userId);
      print('User bookings count: ${userBookings.length}');
      
      for (var booking in userBookings) {
        print('  ${booking.id}: ${booking.carName} - ${booking.getStatusText()} - ${booking.getPaymentStatusText()}');
        print('    Actions: ${booking.getAvailableActions()}');
        print('    Can be deleted: ${booking.canBeDeleted()}');
        if (booking.isRefunded) {
          print('    Refund amount: ${booking.formattedRefundAmount}');
        }
      }
      
      final stats = await getBookingStatsByUser(userId);
      print('Stats: $stats');
      
      final paymentStats = await getPaymentStatsByUser(userId);
      print('Payment Stats: $paymentStats');
    } catch (e) {
      print('❌ Error in booking debug: $e');
    }
    
    print('======================================');
  }
}