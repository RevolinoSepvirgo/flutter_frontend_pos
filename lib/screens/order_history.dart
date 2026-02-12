import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../providers/auth_provider.dart';

// Palette Warna Premium (sesuai dashboard)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);

// Provider untuk order list
final orderListProvider = FutureProvider<List<Order>>((ref) async {
  final token = ref.watch(authProvider).token;
  if (token == null) return [];
  
  final orderService = OrderService();
  return await orderService.getAllOrders(token);
});

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  // Group orders by date
  Map<String, List<Order>> _groupOrdersByDate(List<Order> orders) {
    final Map<String, List<Order>> grouped = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    for (var order in orders) {
      final dateKey = dateFormat.format(order.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(order);
    }
    
    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDate = DateTime(date.year, date.month, date.day);
    
    if (orderDate == today) {
      return 'Hari Ini';
    } else if (orderDate == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderListProvider);

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Riwayat Transaksi",
                    style: TextStyle(
                      color: colorDeepSage,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(orderListProvider),
                    icon: const Icon(Icons.refresh, color: colorDeepSage),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: colorDeepSage.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorDeepSage.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort by date descending (newest first)
                  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  // Group by date
                  final groupedOrders = _groupOrdersByDate(orders);
                  final sortedDates = groupedOrders.keys.toList()
                    ..sort((a, b) => b.compareTo(a)); // Newest date first

                  return RefreshIndicator(
                    color: colorDeepSage,
                    onRefresh: () async {
                      ref.invalidate(orderListProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 120),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, dateIndex) {
                        final dateKey = sortedDates[dateIndex];
                        final dateOrders = groupedOrders[dateKey]!;
                        final firstOrder = dateOrders.first;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: colorDeepSage,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getDateLabel(firstOrder.createdAt),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorDeepSage,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${dateOrders.length} transaksi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorDeepSage.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Orders for this date
                            ...dateOrders.asMap().entries.map((entry) {
                              final index = entry.key;
                              final order = entry.value;
                              return _OrderCard(
                                order: order,
                                index: index + 1,
                                dateKey: dateKey,
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: colorDeepSage),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(orderListProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorDeepSage,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final int index;
  final String dateKey;

  const _OrderCard({
    required this.order,
    required this.index,
    required this.dateKey,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final timeFormat = DateFormat('HH:mm', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorDeepSage.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => _showOrderDetail(context, order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Number & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorDeepSage.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt,
                          color: colorDeepSage,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.nomorStruk ?? 'Transaksi #$index',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeFormat.format(order.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items Summary (max 2)
              ...order.items.take(2).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.productName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 12),
                  child: Text(
                    '+ ${order.items.length - 2} item lainnya',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Footer: Payment Method & Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getPaymentColor(order.paymentMethod)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPaymentIcon(order.paymentMethod),
                          size: 14,
                          color: _getPaymentColor(order.paymentMethod),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getPaymentLabel(order.paymentMethod),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getPaymentColor(order.paymentMethod),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(order.total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorDeepSage,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'debit':
        return Colors.blue;
      case 'qris':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'debit':
        return Icons.credit_card;
      case 'qris':
        return Icons.qr_code_scanner;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'debit':
        return 'Debit';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }

  void _showOrderDetail(BuildContext context, Order order) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateTimeFormat = DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorMilkWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Transaksi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorDeepSage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Nomor Struk
                  if (order.nomorStruk != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorDeepSage.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            order.nomorStruk!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Date & Time
                  Text(
                    dateTimeFormat.format(order.createdAt),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Items
                  const Text(
                    'Detail Pesanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...order.items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorDeepSage.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorDeepSage,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(item.price),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(item.subtotal),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorDeepSage.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(fontSize: 14),
                            ),
                            Row(
                              children: [
                                Icon(
                                  _getPaymentIcon(order.paymentMethod),
                                  size: 18,
                                  color: _getPaymentColor(order.paymentMethod),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getPaymentLabel(order.paymentMethod),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _getPaymentColor(order.paymentMethod),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (order.bayar != null) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bayar', style: TextStyle(fontSize: 14)),
                              Text(
                                currencyFormat.format(order.bayar!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        if (order.kembali != null && order.kembali! > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembali', style: TextStyle(fontSize: 14)),
                              Text(
                                currencyFormat.format(order.kembali!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat.format(order.total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorDeepSage,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}