import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/Car.dart';

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
  final _daysController = TextEditingController();
  final _nameController = TextEditingController();
  final _userIdController = TextEditingController();

  // Form data
  int rentalDays = 1;
  bool needDriver = false;
  double basePrice = 0.0;
  double driverPrice = 200000.0; // 200k for driver
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCarDetail();
    _daysController.text = '1';
  }

  @override
  void dispose() {
    _daysController.dispose();
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
          // PERBAIKAN: Pastikan konversi ke double
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

  void _calculateTotalPrice() {
    double subtotal = basePrice * rentalDays;
    double driverCost = needDriver ? driverPrice : 0.0;
    setState(() {
      totalPrice = subtotal + driverCost;
    });
  }

  void _onDaysChanged(String value) {
    int days = int.tryParse(value) ?? 1;
    if (days < 1) days = 1;
    setState(() {
      rentalDays = days;
      _daysController.text = days.toString();
      _calculateTotalPrice();
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

  Future<void> _processBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      ),
    );

    // Simulate booking process
    await Future.delayed(const Duration(seconds: 2));

    // Close loading dialog
    Navigator.pop(context);

    // Show success dialog
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
            Text('Mobil: ${car!.nama}'),
            Text('Pemesan: ${_nameController.text}'),
            Text('ID User: ${_userIdController.text}'),
            Text('Lama Sewa: $rentalDays hari'),
            Text('Dengan Sopir: ${needDriver ? "Ya" : "Tidak"}'),
            const Divider(),
            Text(
              'Total: ${_formatCurrency(totalPrice)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
        ],
      ),
    );
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

            // Lama Hari Input
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Lama Sewa (hari):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wajib diisi';
                      }
                      int? days = int.tryParse(value);
                      if (days == null || days < 1) {
                        return 'Min 1 hari';
                      }
                      return null;
                    },
                    onChanged: _onDaysChanged,
                  ),
                ),
              ],
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
              'Subtotal',
              _formatCurrency(basePrice * rentalDays),
            ),
            if (needDriver) ...[
              _buildPriceItem(
                'Biaya sopir',
                _formatCurrency(driverPrice),
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
          'Lakukan Book',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
