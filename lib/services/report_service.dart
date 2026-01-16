import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';
import '../config/api_config.dart';

class ReportService {
  // GET Dashboard Report
  Future<ReportSummary> getDashboardReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      print('🔄 Fetching dashboard report...');
      print('📍 URL: ${ApiConfig.reportBaseUrl}/api/reports/dashboard');

      final response = await http.get(
        Uri.parse('${ApiConfig.reportBaseUrl}/api/reports/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Periksa koneksi internet Anda.');
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final report = ReportSummary.fromJson(data);
        
        print('✅ Report loaded successfully');
        print('💰 Total Omzet: ${report.summaryHariIni.totalOmzet}');
        print('📦 Transaksi: ${report.summaryHariIni.jumlahTransaksi}');
        print('🏆 Top Products: ${report.produkTerlaris.length}');
        
        return report;
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir. Silakan login kembali.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Gagal mengambil data laporan');
      }
    } catch (e) {
      print('❌ Error fetching report: $e');
      rethrow;
    }
  }

  // Sync transaction to Report Service (dipanggil dari Order Service)
  // Fungsi ini opsional, biasanya sync dilakukan dari backend Java ke Python
  Future<void> syncTransaction(Map<String, dynamic> transactionData) async {
    try {
      print('🔄 Syncing transaction to report service...');
      print('📍 URL: ${ApiConfig.reportBaseUrl}/api/reports/sync');

      final response = await http.post(
        Uri.parse('${ApiConfig.reportBaseUrl}/api/reports/sync'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Sync timeout');
        },
      );

      print('📊 Sync response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Transaction synced successfully');
      } else {
        print('⚠️ Sync failed but continuing...');
        // Tidak throw error karena ini bukan critical operation
      }
    } catch (e) {
      print('⚠️ Error syncing transaction (non-critical): $e');
      // Tidak throw error, hanya log
    }
  }
}