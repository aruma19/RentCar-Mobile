import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_133_165/pages/BookPage.dart';
import 'dart:convert';
import '../models/Car.dart';
import '../services/HiveService.dart';
import '../models/book.dart';

class BookListPage extends StatefulWidget {
  final String carId;
  final Car? car;

  const BookListPage({super.key, required this.carId, this.car});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  Car? car;
  bool isLoading = true;
  String? errorMessage;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userIdController = TextEditingController();

  // Form data
  DateTime? startDate;
  DateTime? endDate;
  int rentalDays = 1;
  bool needDriver = false;
  double basePrice = 0.0;
  double driverPrice = 200000.0; // 200k for driver
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCarDetail();
    // Set default dates (today + 1 day)
    startDate = DateTime.now().add(const Duration(days: 1));
    endDate = DateTime.now().add(const Duration(days: 2));
    _calculateRentalDays();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchCarDetail() async {
    try {
      final response = await http.get(Uri.parse(
          'https://6839447d6561b8d882af9534.mockapi.io/api/sewa_mobil/mobil/${widget.carId}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        setState(() {
          car = Car.fromJson(json);
          basePrice = car!.harga.toDouble();
          isLoading = false;
          _calculateTotalPrice();
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat detail mobil';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  void _calculateRentalDays() {
    if (startDate != null && endDate != null) {
      setState(() {
        rentalDays = endDate!.difference(startDate!).inDays;
        if (rentalDays < 1) rentalDays = 1;
        _calculateTotalPrice();
      });
    }
  }

  void _calculateTotalPrice() {
    double subtotal = basePrice * rentalDays;
    double driverCost = needDriver ? driverPrice * rentalDays : 0.0;
    setState(() {
      totalPrice = subtotal + driverCost;
    });
  }

  void _onDriverToggle(bool? value) {
    setState(() {
      needDriver = value ?? false;
      _calculateTotalPrice();
    });
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}'
        '/${date.year}';
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Mulai Rental',
      cancelText: 'Batal',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
        // If end date is before start date, update end date
        if (endDate != null && endDate!.isBefore(picked)) {
          endDate = picked.add(const Duration(days: 1));
        }
        _calculateRentalDays();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ??
          (startDate?.add(const Duration(days: 1)) ??
              DateTime.now().add(const Duration(days: 2))),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Selesai Rental',
      cancelText: 'Batal',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
        _calculateRentalDays();
      });
    }
  }

  Future<void> _processBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih tanggal mulai dan selesai rental'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show payment selection dialog first
    final paymentResult = await _showPaymentSelectionDialog();
    if (paymentResult == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      ),
    );

    try {
      // Create booking object
      final booking = Book(
        id: HiveService.generateBookingId(),
        carId: widget.carId,
        carName: car!.nama,
        carMerk: car!.merk,
        userName: _nameController.text.trim(),
        userId: _userIdController.text.trim(),
        rentalDays: rentalDays,
        needDriver: needDriver,
        basePrice: basePrice,
        driverPrice: needDriver ? driverPrice : 0.0,
        totalPrice: totalPrice,
        startDate: startDate!,
        endDate: endDate!,
        bookingDate: DateTime.now(),
        createdAt: DateTime.now(),
        status: 'active',
        paymentStatus: paymentResult['status'],
        paidAmount: paymentResult['amount'],
        paymentDate: paymentResult['status'] == 'paid' ? DateTime.now() : null,
      );

      // Save booking to Hive
      await HiveService.saveBooking(booking);

      // Simulate processing time
      await Future.delayed(const Duration(seconds: 1));

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text('Booking Berhasil!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID Booking: ${booking.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Mobil: ${car!.nama}'),
                Text('Pemesan: ${_nameController.text}'),
                Text('ID User: ${_userIdController.text}'),
                Text(
                    'Tanggal Rental: ${_formatDate(startDate)} - ${_formatDate(endDate)}'),
                Text('Lama Sewa: $rentalDays hari'),
                Text('Dengan Sopir: ${needDriver ? "Ya" : "Tidak"}'),
                const Divider(),
                Text(
                  'Total: ${_formatCurrency(totalPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Status Pembayaran: ${_getPaymentStatusText(booking.paymentStatus)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getPaymentStatusColor(booking.paymentStatus),
                  ),
                ),
                if (booking.paidAmount > 0)
                  Text(
                    'Dibayar: ${_formatCurrency(booking.paidAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous page
                },
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous page
                  // Navigate to BookPage to see the booking
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookPage()),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lihat Booking'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text('Booking Gagal!'),
              ],
            ),
            content: Text('Terjadi kesalahan saat menyimpan booking: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showPaymentSelectionDialog() async {
    String paymentType = 'pending';
    double amount = 0.0;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih Metode Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${_formatCurrency(totalPrice)}'),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('Booking Saja (Bayar Nanti)'),
                subtitle: const Text('Rp 0'),
                value: 'pending',
                groupValue: paymentType,
                onChanged: (value) {
                  setDialogState(() {
                    paymentType = value!;
                    amount = 0.0;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('DP 50%'),
                subtitle: Text(_formatCurrency(totalPrice * 0.5)),
                value: 'dp',
                groupValue: paymentType,
                onChanged: (value) {
                  setDialogState(() {
                    paymentType = value!;
                    amount = totalPrice * 0.5;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Bayar Lunas'),
                subtitle: Text(_formatCurrency(totalPrice)),
                value: 'paid',
                groupValue: paymentType,
                onChanged: (value) {
                  setDialogState(() {
                    paymentType = value!;
                    amount = totalPrice;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'status': paymentType,
                'amount': amount,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Belum Bayar';
      case 'dp':
        return 'DP (50%)';
      case 'paid':
        return 'Lunas';
      default:
        return 'Unknown';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'dp':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title:
            const Text("Booking Mobil", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[800],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _fetchCarDetail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (car == null) {
      return const Center(
        child: Text('Data mobil tidak ditemukan'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarSpecCard(),
            const SizedBox(height: 16),
            _buildDateSelectionCard(),
            const SizedBox(height: 16),
            _buildRentalOptionsCard(),
            const SizedBox(height: 16),
            _buildCustomerInfoCard(),
            const SizedBox(height: 16),
            _buildPricingCard(),
            const SizedBox(height: 24),
            _buildBookButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarSpecCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spesifikasi Mobil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecItem('ID', car!.id),
            _buildSpecItem('Nama', car!.nama),
            _buildSpecItem('Merk', car!.merk),
            _buildSpecItem('Tahun', car!.year.toString()),
            _buildSpecItem('Harga per Hari', _formatCurrency(basePrice)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal Rental',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 16),

            // Start Date & End Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Mulai:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(startDate),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: startDate == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                              Icon(Icons.calendar_today,
                                  color: Colors.teal[800]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Selesai:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(endDate),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: endDate == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                              Icon(Icons.calendar_today,
                                  color: Colors.teal[800]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Duration Display
            if (startDate != null && endDate != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.teal[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Lama Sewa: $rentalDays hari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[800],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalOptionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opsi Rental',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 16),

            // Driver Option
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dengan Sopir:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: needDriver,
                      onChanged: _onDriverToggle,
                      activeColor: Colors.teal[800],
                    ),
                    const Text('Tidak'),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: true,
                      groupValue: needDriver,
                      onChanged: _onDriverToggle,
                      activeColor: Colors.teal[800],
                    ),
                    const Text('Ya'),
                  ],
                ),
              ],
            ),

            if (needDriver)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${_formatCurrency(driverPrice)} per hari',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Pemesan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Pemesan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pemesan wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'ID User',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ID User wajib diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Harga',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceItem(
              'Harga per hari',
              _formatCurrency(basePrice),
            ),
            _buildPriceItem(
              'Lama sewa',
              '$rentalDays hari',
            ),
            _buildPriceItem(
              'Subtotal mobil',
              _formatCurrency(basePrice * rentalDays),
            ),
            if (needDriver) ...[
              _buildPriceItem(
                'Biaya sopir per hari',
                _formatCurrency(driverPrice),
              ),
              _buildPriceItem(
                'Total biaya sopir',
                _formatCurrency(driverPrice * rentalDays),
              ),
            ],
            const Divider(thickness: 2),
            _buildPriceItem(
              'Total Harga',
              _formatCurrency(totalPrice),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.teal[800] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _processBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Text(
          'Lakukan Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
