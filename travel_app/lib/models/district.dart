class District {
  final int id;
  final String name;

  District({required this.id, required this.name});

  // Hàm này giúp xẻ thịt file JSON từ Backend thành Object trong Flutter
  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id:
          json['district_id'] ??
          0, // Trùng khớp với tên cột trong Database/Schema của Python
      name: json['name'] ?? 'Chưa rõ',
    );
  }
}
