import 'package:flutter/material.dart';

/// Model untuk item bantuan
class HelpItem {
  final String title;
  final List<String> content;
  final IconData icon;
  final Color color;

  HelpItem({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });
}

/// Halaman Bantuan untuk aplikasi Rental Kendaraan
class HelpPage extends StatefulWidget {
  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<HelpItem> helpItems = [
    HelpItem(
      title: 'Cara Login',
      content: [
        'Masukkan username dan password Anda pada kolom yang tersedia',
        'Klik tombol "Login" untuk masuk ke aplikasi',
        'Jika gagal, pastikan username dan password benar'
      ],
      icon: Icons.login_rounded,
      color: Colors.blue,
    ),
    HelpItem(
      title: 'Melihat Daftar Kendaraan',
      content: [
        'Setelah login, Anda akan melihat halaman daftar kendaraan',
        'Kendaraan terbagi menjadi dua kategori: mobil dan motor',
        'Scroll untuk melihat seluruh kendaraan yang tersedia'
      ],
      icon: Icons.directions_car_rounded,
      color: Colors.teal,
    ),
    HelpItem(
      title: 'Melihat Detail Kendaraan',
      content: [
        'Klik salah satu kendaraan untuk melihat detail lengkap',
        'Detail meliputi nama, harga sewa, deskripsi, dan gambar',
        'Tekan tombol "Sewa Sekarang" untuk melanjutkan'
      ],
      icon: Icons.info_outline_rounded,
      color: Colors.orange,
    ),
    HelpItem(
      title: 'Melakukan Pemesanan',
      content: [
        'Klik tombol "Sewa Sekarang" pada detail kendaraan',
        'Isi informasi pemesanan seperti tanggal sewa dan durasi',
        'Klik tombol "Pesan" untuk menyelesaikan pemesanan',
        'Pastikan Anda sudah login sebelum memesan'
      ],
      icon: Icons.shopping_cart_rounded,
      color: Colors.green,
    ),
    HelpItem(
      title: 'Melihat Status Pemesanan',
      content: [
        'Buka halaman "Pesanan Saya" di bagian bawah aplikasi',
        'Lihat status pesanan: Dipesan, Diproses, atau Selesai',
        'Anda dapat membatalkan pesanan jika belum diproses'
      ],
      icon: Icons.assignment_rounded,
      color: Colors.purple,
    ),
    HelpItem(
      title: 'Mengelola Favorit',
      content: [
        'Tap ikon hati pada detail kendaraan untuk menambah favorit',
        'Akses daftar favorit melalui menu navigasi',
        'Hapus dari favorit dengan tap ikon hati merah'
      ],
      icon: Icons.favorite_rounded,
      color: Colors.pink,
    ),
    HelpItem(
      title: 'Logout',
      content: [
        'Tekan ikon logout di pojok kanan atas aplikasi',
        'Anda akan keluar dari akun dan kembali ke halaman login',
        'Gunakan kembali username dan password untuk login ulang'
      ],
      icon: Icons.logout_rounded,
      color: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildHelpList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[700]!, Colors.teal[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap pada setiap topik untuk melihat panduan detail',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: helpItems.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildHelpItem(helpItems[index], index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHelpItem(HelpItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.color.withOpacity(0.8),
                  item.color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey[800],
            ),
          ),
          subtitle: Text(
            'Tap untuk melihat panduan detail',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          iconColor: item.color,
          collapsedIconColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.color.withOpacity(0.05),
                    item.color.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: item.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.list_alt_rounded,
                            size: 16,
                            color: item.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Langkah-langkah',
                            style: TextStyle(
                              color: item.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...item.content.asMap().entries.map((entry) {
                      int stepIndex = entry.key;
                      String step = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    item.color.withOpacity(0.8),
                                    item.color,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${stepIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}