// import 'package:flutter/material.dart';
// import '../models/book.dart';
// import '../services/HiveService.dart';
// import 'detailBook.dart';

// class HistoryBookPage extends StatefulWidget {
//   const HistoryBookPage({super.key});

//   @override
//   State<HistoryBookPage> createState() => _HistoryBookPageState();
// }

// class _HistoryBookPageState extends State<HistoryBookPage> with TickerProviderStateMixin {
//   List<Book> allHistory = [];
//   List<Book> filteredHistory = [];
//   bool isLoading = true;
//   String selectedFilter = 'all'; // 'all', 'completed', 'cancelled'
  
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadHistory();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadHistory() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final allBookings = await HiveService.getAllBookings();
//       // Filter hanya booking yang completed atau cancelled
//       final historyBookings = allBookings.where((booking) => 
//           booking.isCompleted || booking.isCancelled
//       ).toList();
      
//       setState(() {
//         allHistory = historyBookings;
//         _filterHistory();
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       _showErrorSnackBar('Gagal memuat history: $e');
//     }
//   }

//   void _filterHistory() {
//     switch (selectedFilter) {
//       case 'all':
//         filteredHistory = List.from(allHistory);
//         break;
//       case 'completed':
//         filteredHistory = allHistory.where((book) => book.isCompleted).toList();
//         break;
//       case 'cancelled':
//         filteredHistory = allHistory.where((book) => book.isCancelled).toList();
//         break;
//     }
    
//     // Sort by booking date (newest first)
//     filteredHistory.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
//   }

//   void _onTabChanged(int index) {
//     String newFilter;
//     switch (index) {
//       case 0:
//         newFilter = 'all';
//         break;
//       case 1:
//         newFilter = 'completed';
//         break;
//       case 2:
//         newFilter = 'cancelled';
//         break;
//       default:
//         newFilter = 'all';
//     }
    
//     setState(() {
//       selectedFilter = newFilter;
//       _filterHistory();
//     });
//   }

//   Future<void> _deleteBooking(Book booking) async {
//     final confirmed = await _showDeleteConfirmation();
//     if (confirmed == true) {
//       try {
//         await HiveService.deleteBooking(booking.id);
//         await _loadHistory();
//         _showSuccessSnackBar('History berhasil dihapus');
//       } catch (e) {
//         _showErrorSnackBar('Gagal menghapus history: $e');
//       }
//     }
//   }

//   Future<bool?> _showDeleteConfirmation() {
//     return showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Konfirmasi Hapus'),
//         content: const Text('Apakah Anda yakin ingin menghapus history ini?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Batal'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Hapus'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: Column(
//         children: [
//           // Custom header
//           Container(
//             color: Colors.teal[800],
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   // Tab section
//                   TabBar(
//                     controller: _tabController,
//                     onTap: _onTabChanged,
//                     labelColor: Colors.white,
//                     unselectedLabelColor: Colors.white70,
//                     indicatorColor: Colors.white,
//                     tabs: [
//                       Tab(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(Icons.history, size: 20),
//                             const SizedBox(height: 4),
//                             Text('Semua', style: TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                       ),
//                       Tab(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(Icons.check_circle, size: 20),
//                             const SizedBox(height: 4),
//                             Text('Selesai', style: TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                       ),
//                       Tab(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(Icons.cancel, size: 20),
//                             const SizedBox(height: 4),
//                             Text('Batal', style: TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Body content
//           Expanded(child: _buildBody()),
//         ],
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(color: Colors.teal),
//       );
//     }

//     if (filteredHistory.isEmpty) {
//       return _buildEmptyState();
//     }

//     return RefreshIndicator(
//       onRefresh: _loadHistory,
//       color: Colors.teal,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: filteredHistory.length,
//         itemBuilder: (context, index) {
//           final booking = filteredHistory[index];
//           return _buildHistoryCard(booking);
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     String emptyMessage;
//     IconData emptyIcon;
    
//     switch (selectedFilter) {
//       case 'completed':
//         emptyMessage = 'Tidak ada booking yang selesai';
//         emptyIcon = Icons.check_circle_outline;
//         break;
//       case 'cancelled':
//         emptyMessage = 'Tidak ada booking yang dibatalkan';
//         emptyIcon = Icons.cancel_outlined;
//         break;
//       default:
//         emptyMessage = 'Belum ada history booking';
//         emptyIcon = Icons.history;
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             emptyIcon,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             emptyMessage,
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Pull down untuk refresh',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHistoryCard(Book booking) {
//     Color statusColor;
//     Color statusBackgroundColor;
//     IconData statusIcon;
    
//     switch (booking.status) {
//       case 'completed':
//         statusColor = Colors.green;
//         statusBackgroundColor = Colors.green[50]!;
//         statusIcon = Icons.check_circle;
//         break;
//       case 'cancelled':
//         statusColor = Colors.red;
//         statusBackgroundColor = Colors.red[50]!;
//         statusIcon = Icons.cancel;
//         break;
//       default:
//         statusColor = Colors.grey;
//         statusBackgroundColor = Colors.grey[50]!;
//         statusIcon = Icons.help;
//     }

//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => DetailBookPage(bookingId: booking.id),
//             ),
//           );
//         },
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header dengan status
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'ID: ${booking.id}',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.teal[800],
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: statusBackgroundColor,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(statusIcon, size: 16, color: statusColor),
//                             const SizedBox(width: 4),
//                             Text(
//                               booking.status.toUpperCase(),
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: statusColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: booking.paymentStatusColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           booking.paymentStatusText,
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: booking.paymentStatusColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 12),
              
//               // Car Info
//               Row(
//                 children: [
//                   Icon(Icons.directions_car, color: Colors.grey[600], size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       '${booking.carName} (${booking.carMerk})',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 8),
              
//               // Customer Info
//               Row(
//                 children: [
//                   Icon(Icons.person, color: Colors.grey[600], size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     booking.userName,
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                   const SizedBox(width: 16),
//                   Icon(Icons.badge, color: Colors.grey[600], size: 16),
//                   const SizedBox(width: 4),
//                   Text(
//                     booking.userId,
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 8),
              
//               // Date Info
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Rental: ${booking.dateRange}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 8),
              
//               // Booking Date
//               Row(
//                 children: [
//                   Icon(Icons.event, color: Colors.grey[600], size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Dibooking: ${booking.formattedBookingDate}',
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                 ],
//               ),
              
//               const Divider(height: 20),
              
//               // Price and Actions
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         booking.formattedTotalPrice,
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.teal[800],
//                         ),
//                       ),
//                       if (booking.isPaid)
//                         Text(
//                           'Lunas',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.green[600],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       IconButton(
//                         onPressed: () => _deleteBooking(booking),
//                         icon: Icon(Icons.delete, color: Colors.red[600]),
//                         tooltip: 'Hapus',
//                       ),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         size: 16,
//                         color: Colors.grey[400],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }