import 'package:flutter/material.dart';
import 'package:travel_app/screens/trips/create_trip_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with SingleTickerProviderStateMixin {
  bool _isFabOpen = false;

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Chỉnh màu nền đen xịn xò (nếu ông có AppColors.background thì xài)
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // 1. NỘI DUNG CHÍNH CỦA MÀN HÌNH
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                const SizedBox(height: 10),
                // Tiêu đề to đùng
                const Text(
                  "Chuyến đi",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 30),

                // Card: Chuyến đi tới TP.HCM
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hình ảnh bo góc
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1583417319070-4a69db38a482?q=80&w=200&auto=format&fit=crop', // Ảnh cầu Sài Gòn ban đêm giả lập
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Cột thông tin chữ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Chuyến đi của tôi",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Dòng: Thêm ngày tháng
                          Row(
                            children: const [
                              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                "10 ngày",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline, // Chữ gạch chân y hệt ảnh
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Dòng: 1 lượt lưu
                          Row(
                            children: const [
                              Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                "1 lượt lưu",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Nút 3 chấm
                    const Icon(Icons.more_vert, color: Colors.grey),
                  ],
                ),

                const SizedBox(height: 40),

                // Tiêu đề: Chuyến đi đã hoàn tất
                const Text(
                  "Chuyến đi đã hoàn tất",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),

                // Dòng chú thích
                Text(
                  "Các chuyến đi đã hoàn thành của bạn sẽ xuất hiện tại đây.",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 25),

                // Card: chuyến đi hoàn tất
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hình ảnh bo góc
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1583417319070-4a69db38a482?q=80&w=200&auto=format&fit=crop', // Ảnh cầu Sài Gòn ban đêm giả lập
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Cột thông tin chữ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Đi ăn 2 ngày",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Dòng: Thêm ngày tháng
                          Row(
                            children: const [
                              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                "2 ngày",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline, // Chữ gạch chân y hệt ảnh
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Dòng: 1 lượt lưu
                          Row(
                            children: const [
                              Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                "1 lượt lưu",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Nút 3 chấm
                    const Icon(Icons.more_vert, color: Colors.grey),

                    
                  ],
                ),
                const SizedBox(height: 30),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hình ảnh bo góc
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1583417319070-4a69db38a482?q=80&w=200&auto=format&fit=crop', // Ảnh cầu Sài Gòn ban đêm giả lập
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Cột thông tin chữ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hẹn với ghệ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Dòng: Thêm ngày tháng
                          Row(
                            children: const [
                              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                "1 ngày",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline, // Chữ gạch chân y hệt ảnh
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Dòng: 1 lượt lưu
                          Row(
                            children: const [
                              Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                "1 lượt lưu",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Nút 3 chấm
                    const Icon(Icons.more_vert, color: Colors.grey),

                    
                  ],
                ),
              ],
            ),
          ),

          // 2. LỚP PHỦ MÀU ĐEN MỜ KHI MỞ MENU FAB (Dim background)
          AnimatedOpacity(
            opacity: _isFabOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _isFabOpen
                ? GestureDetector(
                    onTap: _toggleFab, // Bấm ra ngoài để đóng
                    child: Container(color: Colors.black.withOpacity(0.7)),
                  )
                : const SizedBox.shrink(),
          ), 
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFabOpen)
                  Column(
                    children: [                      
                      // 1. NÚT TẠO CHUYẾN ĐI THỦ CÔNG
                      _buildFabOption(
                        title: "Tạo một chuyến đi",
                        icon: Icons.add_location_alt_outlined,
                        heroTag: "btn_create_trip_manual",
                        onPressed: () {
                          _toggleFab();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateTripScreen(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20), // Khoảng cách giữa 2 nút
                      
                      // 2. NÚT TẠO CHUYẾN ĐI VỚI AI
                      _buildFabOption(
                        title: "Tạo chuyến đi với AI",
                        icon: Icons.auto_awesome, // Tui trả lại cái icon lấp lánh cho AI nhé
                        heroTag: "btn_create_trip_ai", // Đã đổi heroTag chống crash
                        onPressed: () {
                          _toggleFab();
                          // Gọi qua màn hình AI ở đây
                        },
                      ),
                    ],
                  ),
                
                if (_isFabOpen) const SizedBox(height: 15),
                
                // Nút Chính (Đổi qua lại giữa Icon + và Icon X)
                FloatingActionButton(
                  heroTag: "btn_main_toggle",
                  backgroundColor: Colors.white,
                  onPressed: _toggleFab,
                  shape: const CircleBorder(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      _isFabOpen ? Icons.close : Icons.add,
                      key: ValueKey<bool>(_isFabOpen),
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            
          ),
                    
        ],        
      ),      
    );
  }
}

// Hàm dùng chung để tạo nút FAB có text (Đồng nhất giao diện)
  Widget _buildFabOption({
    required String title,
    required IconData icon,
    required String heroTag,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 250, // Cố định chiều dài cho cả 2 nút
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: heroTag, // Tránh lỗi trùng heroTag
              backgroundColor: Colors.white,
              onPressed: onPressed,
              shape: const CircleBorder(),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
          ],
        ),
      ),
    );
  }