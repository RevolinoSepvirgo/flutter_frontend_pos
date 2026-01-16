import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';

// Palette Warna Premium (Konsisten dengan Dashboard/POS)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);
const Color colorDeepSageLight = Color(0xFFE8EEDF);

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadDashboard();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(reportProvider.notifier).refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(dateFormat.format(now), reportState.isLoading),
            Expanded(
              child: reportState.isLoading && reportState.report == null
                  ? const Center(child: CircularProgressIndicator(color: colorDeepSage))
                  : reportState.error != null && reportState.report == null
                      ? _buildErrorState(reportState.error!)
                      : reportState.report == null
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: colorDeepSage,
                              onRefresh: _handleRefresh,
                              child: _buildReportContent(reportState.report!),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String date, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date.toUpperCase(), 
                  style: const TextStyle(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey)),
              Text("Laporan", 
                  style: TextStyle(color: colorDeepSage, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
          IconButton(
            onPressed: isLoading ? null : _handleRefresh,
            icon: const Icon(Icons.refresh_rounded, color: colorDeepSage),
            style: IconButton.styleFrom(backgroundColor: colorDeepSage.withOpacity(0.05)),
          )
        ],
      ),
    );
  }

  Widget _buildReportContent(ReportSummary report) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Padding bawah 130px agar tidak tertutup Dock Dashboard
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(report.summaryHariIni),
          const SizedBox(height: 35),
          _buildSectionTitle('METODE PEMBAYARAN'),
          const SizedBox(height: 15),
          _buildPaymentMethodStats(report.metodePermbayaran),
          const SizedBox(height: 35),
          _buildSectionTitle('PRODUK TERLARIS'),
          const SizedBox(height: 15),
          _buildTopProducts(report.produkTerlaris),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 3),
    );
  }

  Widget _buildSummarySection(DailySummary summary) {
    return Row(
      children: [
        Expanded(
          child: _ModernSummaryCard(
            title: 'Omzet Hari Ini',
            value: _currencyFormat.format(summary.totalOmzet),
            icon: Icons.account_balance_wallet_rounded,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _ModernSummaryCard(
            title: 'Transaksi',
            value: '${summary.jumlahTransaksi}',
            icon: Icons.confirmation_number_rounded,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodStats(PaymentMethodStats stats) {
    final methods = stats.toList();
    final totalAll = stats.totalAll;

    if (totalAll == 0) return _buildNoDataCard();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: colorDeepSage.withOpacity(0.03), blurRadius: 20)],
      ),
      child: Column(
        children: methods.map((method) {
          if (method.count == 0) return const SizedBox.shrink();
          final percentage = method.getPercentage(totalAll);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(method.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(method.method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Text(_currencyFormat.format(method.total), style: const TextStyle(fontWeight: FontWeight.w900, color: colorDeepSage)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: colorMilkWhite,
                    valueColor: const AlwaysStoppedAnimation(colorDeepSage),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProducts(List<TopProduct> products) {
    if (products.isEmpty) return _buildNoDataCard();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: colorDeepSage.withOpacity(0.03), blurRadius: 20)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (context, index) => Divider(color: colorMilkWhite, height: 1),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: CircleAvatar(
              backgroundColor: index == 0 ? colorDeepSage : colorDeepSage.withOpacity(0.1),
              child: Text('${index + 1}', style: TextStyle(color: index == 0 ? Colors.white : colorDeepSage, fontWeight: FontWeight.bold)),
            ),
            title: Text(product.produk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: Text('${product.terjual} terjual', style: const TextStyle(fontWeight: FontWeight.w900, color: colorDeepSage)),
          );
        },
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: const Center(child: Text("Belum ada aktivitas hari ini", style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: colorDeepSage.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('Data Laporan Belum Tersedia', style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: () => ref.read(reportProvider.notifier).loadDashboard(), child: const Text("Muat Ulang")),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Text("Terjadi kesalahan: $error", style: const TextStyle(color: Colors.redAccent)),
    );
  }
}

class _ModernSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isPrimary;

  const _ModernSummaryCard({required this.title, required this.value, required this.icon, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? colorDeepSage : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: isPrimary ? colorDeepSage.withOpacity(0.3) : colorDeepSage.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isPrimary ? colorMilkWhite : colorDeepSage, size: 28),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(color: isPrimary ? colorMilkWhite.withOpacity(0.6) : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: TextStyle(color: isPrimary ? colorMilkWhite : colorDeepSage, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ],
      ),
    );
  }
}