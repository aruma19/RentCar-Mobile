import 'package:flutter/material.dart';

/// Model untuk item bantuan
class HelpItem {
  final String title;
  final List<String> content;
  final IconData icon;

  HelpItem({
    required this.title,
    required this.content,
    required this.icon,
  });
}

/// Halaman Bantuan untuk aplikasi Rental Kendaraan
class HelpPage extends StatelessWidget {
  final List<HelpItem> helpItems = [
    HelpItem(
      title: 'Cara Login',
      content: [
        '1. Masukkan username dan password Anda pada kolom yang tersedia.',
        '2. Klik tombol "Login" untuk masuk ke aplikasi.',
        '3. Jika gagal, pastikan username dan password benar.'
      ],
      icon: Icons.login,
    ),
    HelpItem(
      title: 'Melihat Daftar Kendaraan',
      content: [
        '1. Setelah login, Anda akan melihat halaman daftar kendaraan.',
        '2. Kendaraan terbagi menjadi dua kategori: mobil dan motor.',
        '3. Anda dapat scroll untuk melihat seluruh kendaraan yang tersedia.'
      ],
      icon: Icons.directions_car,
    ),
    HelpItem(
      title: 'Melihat Detail Kendaraan',
      content: [
        '1. Klik salah satu kendaraan dari daftar untuk melihat detail lengkap.',
        '2. Detail meliputi nama kendaraan, harga sewa, deskripsi, dan gambar.',
        '3. Anda juga dapat menekan tombol "Sewa Sekarang" dari halaman ini.'
      ],
      icon: Icons.info_outline,
    ),
    HelpItem(
      title: 'Melakukan Pemesanan',
      content: [
        '1. Klik tombol "Sewa Sekarang" pada detail kendaraan.',
        '2. Isi informasi pemesanan seperti tanggal sewa dan durasi.',
        '3. Klik tombol "Pesan" untuk menyelesaikan pemesanan.',
        '4. Pastikan Anda sudah login sebelum memesan.'
      ],
      icon: Icons.shopping_cart,
    ),
    HelpItem(
      title: 'Melihat Status Pemesanan',
      content: [
        '1. Buka halaman "Pesanan Saya" di bagian bawah aplikasi.',
        '2. Di sana Anda bisa melihat status pesanan Anda: Dipesan, Diproses, atau Selesai.',
        '3. Anda juga dapat membatalkan pesanan jika belum diproses.'
      ],
      icon: Icons.assignment,
    ),
    HelpItem(
      title: 'Logout',
      content: [
        '1. Tekan ikon logout di pojok kanan atas aplikasi.',
        '2. Anda akan keluar dari akun dan kembali ke halaman login.',
        '3. Gunakan kembali username dan password untuk login ulang.'
      ],
      icon: Icons.logout,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE6E6FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Panduan Penggunaan Aplikasi Rental',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 33, 115, 72),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: helpItems.length,
                  itemBuilder: (context, index) {
                    final item = helpItems[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 33, 115, 72),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: Colors.white),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        backgroundColor: const Color(0xFFF8F3FF),
                        collapsedBackgroundColor: const Color(0xFFF8F3FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide.none,
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide.none,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.content.join("\n"),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
