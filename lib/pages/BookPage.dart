import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/HiveService.dart';
import 'detailBook.dart';

class BookPage extends StatefulWidget {
  final String currentUserId; // TAMBAHKAN PARAMETER INI
  
  const BookPage({super.key, required this.currentUserId});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> with TickerProviderStateMixin {
  List<Book> allBookings = [];
  List<Book> filteredBookings = [];
  bool isLoading = true;
  String selectedFilter = 'all';
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Updated to 5 tabs
    _initAnimations();
    _loadBookings();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// **PERBAIKAN: Load booking berdasarkan USER ID**
  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      // PERBAIKAN: Gunakan getBookingsByUser instead of getAllBookings
      final bookings = await HiveService.getBookingsByUser(widget.currentUserId);
      setState(() {
        allBookings = bookings;
        _filterBookings();
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat data booking: $e');
    }
  }

  void _filterBookings() {
    switch (selectedFilter) {
      case 'all':
        filteredBookings = List.from(allBookings);
        break;
      case 'pending':
        filteredBookings = allBookings.where((book) => book.isPending).toList();
        break;
      case 'active':
        filteredBookings = allBookings.where((book) => book.isActive || book.isConfirmed).toList();
        break;
      case 'completed':
        filteredBookings = allBookings.where((book) => book.isCompleted).toList();
        break;
      case 'cancelled':
        filteredBookings = allBookings.where((book) => book.isCancelled).toList();
        break;
    }
    
    // Sort by booking date (newest first)
    filteredBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
  }

  void _onTabChanged(int index) {
    String newFilter;
    switch (index) {
      case 0:
        newFilter = 'all';
        break;
      case 1:
        newFilter = 'pending';
        break;
      case 2:
        newFilter = 'active';
        break;
      case 3:
        newFilter = 'completed';
        break;
      case 4:
        newFilter = 'cancelled';
        break;
      default:
        newFilter = 'all';
    }
    
    setState(() {
      selectedFilter = newFilter;
      _filterBookings();
    });
  }

  Future<void> _navigateToDetail(Book booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailBookPage(bookingId: booking.id),
      ),
    );
    
    // Refresh data if needed
    if (result != null) {
      _loadBookings();
    }
  }

  /// **PERBAIKAN: Update booking dengan business logic validation**
  Future<void> _updateBookingStatus(Book booking, String newStatus) async {
    try {
      // Gunakan method dari HiveService yang sudah ada validasi
      await HiveService.updateBookingStatus(booking.id, newStatus);
      await _loadBookings();
      _showSuccessSnackBar('Status booking berhasil diupdate menjadi ${_getStatusText(newStatus)}');
    } catch (e) {
      _showErrorSnackBar('Gagal mengupdate status: $e');
    }
  }

/// **PERBAIKAN: Dialog untuk pilihan pembayaran yang benar**
  Future<Map<String, dynamic>?> _showPaymentDialog(Book booking) async {
    // **PERBAIKAN: Logic untuk menentukan opsi pembayaran yang tersedia**
    List<Map<String, dynamic>> paymentOptions = [];
    
    if (booking.paidAmount == 0) {
      // Belum ada pembayaran sama sekali - bisa DP atau lunas
      paymentOptions.addAll([
        {
          'id': 'dp',
          'title': 'DP 50%',
          'subtitle': booking.formatCurrency(booking.totalPrice * 0.5),
          'amount': booking.totalPrice * 0.5,
        },
        {
          'id': 'paid',
          'title': 'Bayar Lunas',
          'subtitle': booking.formattedTotalPrice,
          'amount': booking.totalPrice,
        }
      ]);
    } else if (booking.remainingAmount > 0) {
      // Sudah ada pembayaran DP - hanya bisa bayar sisa
      paymentOptions.add({
        'id': 'remaining',
        'title': 'Bayar Sisa',
        'subtitle': booking.formattedRemainingAmount,
        'amount': booking.remainingAmount,
      });
    }

    if (paymentOptions.isEmpty) {
      return null;
    }

    String selectedPaymentId = paymentOptions.first['id'];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pembayaran Booking ${booking.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // **Payment Summary**
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildPaymentSummaryRow('Total', booking.formattedTotalPrice),
                    _buildPaymentSummaryRow('Sudah Dibayar', booking.formattedPaidAmount),
                    const Divider(),
                    _buildPaymentSummaryRow('Sisa', booking.formattedRemainingAmount),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // **Payment Options**
              if (booking.canProcessPayment()) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: paymentOptions.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> option = entry.value;
                      
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          RadioListTile<String>(
                            title: Text(option['title']),
                            subtitle: Text(option['subtitle']),
                            value: option['id'],
                            groupValue: selectedPaymentId,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPaymentId = value!;
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                Text('Pembayaran tidak dapat diproses untuk booking dengan status ${booking.getStatusText()}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Batal'),
            ),
            if (booking.canProcessPayment())
              ElevatedButton(
                onPressed: () {
                  final selectedOption = paymentOptions.firstWhere(
                    (option) => option['id'] == selectedPaymentId,
                  );
                  Navigator.pop(context, {
                    'type': selectedPaymentId,
                    'amount': selectedOption['amount'],
                    'title': selectedOption['title'],
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proses'),
              ),
          ],
        ),
      ),
    );
  }

  /// **Helper method untuk payment summary row**
  Widget _buildPaymentSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// **PERBAIKAN: Method untuk proses pembayaran yang benar**
  Future<void> _processPayment(Book booking) async {
    final paymentResult = await _showPaymentDialog(booking);
    if (paymentResult == null) return;

    try {
      String paymentType = paymentResult['type'];
      double amount = paymentResult['amount'];
      String title = paymentResult['title'];
      
      if (paymentType == 'remaining') {
        // **Gunakan method khusus untuk pembayaran sisa**
        await HiveService.payBookingRemainingAmount(booking.id);
      } else {
        // **Untuk DP atau pembayaran lunas baru**
        String paymentStatus = paymentType == 'dp' ? 'dp' : 'paid';
        await HiveService.updateBookingPayment(
          booking.id, 
          paymentStatus, 
          amount
        );
      }
      
      await _loadBookings();
      _showSuccessSnackBar('$title berhasil diproses');
    } catch (e) {
      _showErrorSnackBar('Gagal memproses pembayaran: $e');
    }
  }

  /// **PERBAIKAN: Delete booking dengan validasi baru**
  Future<void> _deleteBooking(Book booking) async {
    // **PERBAIKAN: Cek apakah booking bisa dihapus**
    if (!booking.canBeDeleted()) {
      _showErrorSnackBar(
        'Booking tidak dapat dihapus. Harus diselesaikan atau dibatalkan terlebih dahulu.'
      );
      return;
    }

    final confirmed = await _showDeleteConfirmation(booking);
    if (confirmed == true) {
      try {
        await HiveService.deleteBooking(booking.id);
        await _loadBookings();
        _showSuccessSnackBar('Booking berhasil dihapus');
      } catch (e) {
        _showErrorSnackBar('Gagal menghapus booking: $e');
      }
    }
  }

  /// **PERBAIKAN: Dialog konfirmasi delete dengan info refund**
  Future<bool?> _showDeleteConfirmation(Book booking) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Text('Konfirmasi Hapus'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus booking ini?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${booking.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Mobil: ${booking.carName}'),
                  Text('Status: ${booking.getStatusText()}'),
                  Text('Pembayaran: ${booking.getPaymentStatusText()}'),
                  if (booking.isRefunded && booking.refundAmount > 0) ...[
                    const Divider(),
                    Text('Refund: ${booking.formattedRefundAmount}', 
                         style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // **BARU: Info tentang penghapusan**
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data booking akan dihapus permanen dan tidak dapat dikembalikan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'active':
        return 'Aktif';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[700]!, Colors.teal[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Saya',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'User ID: ${widget.currentUserId}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadBookings,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              onTap: _onTabChanged,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              isScrollable: false,
              tabs: const [
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt_rounded, size: 22),
                      SizedBox(height: 4),
                      Text('Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending_actions_rounded, size: 22),
                      SizedBox(height: 4),
                      Text('Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 22),
                      SizedBox(height: 4),
                      Text('Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 22),
                      SizedBox(height: 4),
                      Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_rounded, size: 22),
                      SizedBox(height: 4),
                      Text('Batal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (filteredBookings.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadBookings,
        color: Colors.teal[800],
        backgroundColor: Colors.white,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildBookingCard(filteredBookings[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.teal[800],
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Memuat booking Anda...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage;
    IconData emptyIcon;
    
    switch (selectedFilter) {
      case 'pending':
        emptyMessage = 'Tidak ada booking yang menunggu konfirmasi';
        emptyIcon = Icons.pending_actions_rounded;
        break;
      case 'active':
        emptyMessage = 'Tidak ada booking aktif';
        emptyIcon = Icons.hourglass_empty_rounded;
        break;
      case 'completed':
        emptyMessage = 'Tidak ada booking yang selesai';
        emptyIcon = Icons.check_circle_outline_rounded;
        break;
      case 'cancelled':
        emptyMessage = 'Tidak ada booking yang dibatalkan';
        emptyIcon = Icons.cancel_outlined;
        break;
      default:
        emptyMessage = 'Anda belum memiliki booking';
        emptyIcon = Icons.list_alt_rounded;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[100]!, Colors.teal[200]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  emptyIcon,
                  size: 48,
                  color: Colors.teal[700],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down untuk refresh data',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Book booking) {
    final availableActions = booking.getAvailableActions();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [  
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(booking),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan status dan action menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: ${booking.id}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: booking.getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.getStatusText(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: booking.getStatusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        switch (value) {
                          case 'detail':
                            _navigateToDetail(booking);
                            break;
                          case 'confirm':
                            _updateBookingStatus(booking, 'confirmed');
                            break;
                          case 'activate':
                            _updateBookingStatus(booking, 'active');
                            break;
                          case 'complete':
                            _updateBookingStatus(booking, 'completed');
                            break;
                          case 'cancel':
                            _updateBookingStatus(booking, 'cancelled');
                            break;
                          case 'payment':
                            _processPayment(booking);
                            break;
                          case 'delete':
                            _deleteBooking(booking);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'detail',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Lihat Detail'),
                            ],
                          ),
                        ),
                        if (availableActions.contains('confirm'))
                          const PopupMenuItem(
                            value: 'confirm',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Konfirmasi'),
                              ],
                            ),
                          ),
                        if (availableActions.contains('activate'))
                          const PopupMenuItem(
                            value: 'activate',
                            child: Row(
                              children: [
                                Icon(Icons.play_arrow, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Mulai Rental'),
                              ],
                            ),
                          ),
                        if (availableActions.contains('complete'))
                          const PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(Icons.done_all, size: 18, color: Colors.teal),
                                SizedBox(width: 8),
                                Text('Selesaikan'),
                              ],
                            ),
                          ),
                        if (availableActions.contains('cancel'))
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.close, size: 18, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Batalkan'),
                              ],
                            ),
                          ),
                        if (availableActions.contains('payment'))
                          const PopupMenuItem(
                            value: 'payment',
                            child: Row(
                              children: [
                                Icon(Icons.payment, size: 18, color: Colors.purple),
                                SizedBox(width: 8),
                                Text('Bayar'),
                              ],
                            ),
                          ),
                        // **PERBAIKAN: Delete hanya muncul jika booking bisa dihapus**
                        if (booking.canBeDeleted())
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Car Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: Colors.teal[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.carName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              booking.carMerk,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Payment Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: booking.getPaymentStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: booking.getPaymentStatusColor().withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payment_rounded,
                        size: 16,
                        color: booking.getPaymentStatusColor(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking.getPaymentStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: booking.getPaymentStatusColor(),
                        ),
                      ),
                      if (booking.remainingAmount > 0) ...[
                        const Spacer(),
                        Text(
                          'Sisa: ${booking.formattedRemainingAmount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                      // **BARU: Tampilkan info refund jika ada**
                      if (booking.isRefunded && booking.refundAmount > 0) ...[
                        const Spacer(),
                        Text(
                          'Refund: ${booking.formattedRefundAmount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Date and Driver Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calendar_today_rounded,
                        booking.dateRange,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      '${booking.rentalDays} hari',
                      Colors.green,
                    ),
                    if (booking.needDriver) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.person_pin_rounded,
                        'Sopir',
                        Colors.purple,
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Price and Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.formattedTotalPrice,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        if (booking.paidAmount > 0)
                          Text(
                            'Dibayar: ${booking.formattedPaidAmount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal[600]!, Colors.teal[800]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Extension untuk format currency di Book model
extension BookExtension on Book {
  String formatCurrencyPage(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}