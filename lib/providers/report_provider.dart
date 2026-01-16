import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

// Report State
class ReportState {
  final bool isLoading;
  final ReportSummary? report;
  final String? error;

  ReportState({
    this.isLoading = false,
    this.report,
    this.error,
  });

  ReportState copyWith({
    bool? isLoading,
    ReportSummary? report,
    String? error,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      report: report ?? this.report,
      error: error,
    );
  }
}

// Report Notifier
class ReportNotifier extends StateNotifier<ReportState> {
  final ReportService _service;

  ReportNotifier(this._service) : super(ReportState());

  // Load Dashboard Report
  Future<void> loadDashboard() async {
    print('🔄 ReportNotifier: Loading dashboard...');
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _service.getDashboardReport();
      
      state = state.copyWith(
        isLoading: false,
        report: report,
        error: null,
      );
      
      print('✅ ReportNotifier: Dashboard loaded successfully');
    } catch (e) {
      print('❌ ReportNotifier: Error loading dashboard: $e');
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Refresh Dashboard (pull to refresh)
  Future<void> refreshDashboard() async {
    print('🔄 ReportNotifier: Refreshing dashboard...');
    await loadDashboard();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  void fetchReport() {}
}

// Provider
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final service = ref.watch(reportServiceProvider);
  return ReportNotifier(service);
});