class ApiConfig {
  // Untuk Android Emulator, pakai IP khusus ini
  // IP 10.0.2.2 adalah IP khusus emulator untuk akses localhost komputer
  // Jangan ganti IP ini kalau pakai emulator!
  
  static const String baseIp = '10.0.2.2';
  
  // Service URLs
  static const String userServiceUrl = 'http://$baseIp:3001';
  static const String productServiceUrl = 'http://$baseIp:8000';
  static const String orderServiceUrl = 'http://$baseIp:8080';
  static const String reportBaseUrl = 'http://$baseIp:5000';
  
  // Common headers
  static Map<String, String> headers({String? token}) {
    final Map<String, String> header = {
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      header['Authorization'] = 'Bearer $token';
    }
    
    return header;
  }
}