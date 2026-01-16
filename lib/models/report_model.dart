class ReportSummary {
  final DailySummary summaryHariIni;
  final PaymentMethodStats metodePermbayaran;
  final List<TopProduct> produkTerlaris;

  ReportSummary({
    required this.summaryHariIni,
    required this.metodePermbayaran,
    required this.produkTerlaris,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      summaryHariIni: DailySummary.fromJson(json['summary_hari_ini'] ?? {}),
      metodePermbayaran: PaymentMethodStats.fromJson(json['metode_pembayaran'] ?? {}),
      produkTerlaris: (json['produk_terlaris'] as List<dynamic>?)
              ?.map((item) => TopProduct.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary_hari_ini': summaryHariIni.toJson(),
      'metode_pembayaran': metodePermbayaran.toJson(),
      'produk_terlaris': produkTerlaris.map((item) => item.toJson()).toList(),
    };
  }
}

class DailySummary {
  final double totalOmzet;
  final int jumlahTransaksi;
  final double rataRataPerTransaksi;

  DailySummary({
    required this.totalOmzet,
    required this.jumlahTransaksi,
    required this.rataRataPerTransaksi,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalOmzet: _parseDouble(json['total_omzet']),
      jumlahTransaksi: _parseInt(json['jumlah_transaksi']),
      rataRataPerTransaksi: _parseDouble(json['rata_rata_per_transaksi']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_omzet': totalOmzet,
      'jumlah_transaksi': jumlahTransaksi,
      'rata_rata_per_transaksi': rataRataPerTransaksi,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class PaymentMethodStats {
  final double totalCash;
  final int countCash;
  final double totalDebit;
  final int countDebit;
  final double totalQris;
  final int countQris;

  PaymentMethodStats({
    required this.totalCash,
    required this.countCash,
    required this.totalDebit,
    required this.countDebit,
    required this.totalQris,
    required this.countQris,
  });

  factory PaymentMethodStats.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStats(
      totalCash: _parseDouble(json['total_cash'] ?? json['total_tunai']),
      countCash: _parseInt(json['count_cash'] ?? json['count_tunai']),
      totalDebit: _parseDouble(json['total_debit']),
      countDebit: _parseInt(json['count_debit']),
      totalQris: _parseDouble(json['total_qris']),
      countQris: _parseInt(json['count_qris']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_cash': totalCash,
      'count_cash': countCash,
      'total_debit': totalDebit,
      'count_debit': countDebit,
      'total_qris': totalQris,
      'count_qris': countQris,
    };
  }

  double get totalAll => totalCash + totalDebit + totalQris;
  int get countAll => countCash + countDebit + countQris;

  List<PaymentMethodItem> toList() {
    return [
      PaymentMethodItem(
        method: 'Tunai',
        total: totalCash,
        count: countCash,
        icon: '💵',
      ),
      PaymentMethodItem(
        method: 'Debit',
        total: totalDebit,
        count: countDebit,
        icon: '💳',
      ),
      PaymentMethodItem(
        method: 'QRIS',
        total: totalQris,
        count: countQris,
        icon: '📱',
      ),
    ];
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class PaymentMethodItem {
  final String method;
  final double total;
  final int count;
  final String icon;

  PaymentMethodItem({
    required this.method,
    required this.total,
    required this.count,
    required this.icon,
  });

  double getPercentage(double totalAll) {
    if (totalAll == 0) return 0;
    return (total / totalAll) * 100;
  }
}

class TopProduct {
  final String produk;
  final int terjual;

  TopProduct({
    required this.produk,
    required this.terjual,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      produk: json['produk'] ?? '',
      terjual: _parseInt(json['terjual']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produk': produk,
      'terjual': terjual,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}