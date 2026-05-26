import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/screens/main_screen.dart';

class SharedBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SharedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primaryEmerald,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: currentIndex,
        onTap: (index) {
          if (onTap != null) {
            // Nếu được truyền onTap (như ở MainScreen), thì gọi onTap để đổi tab
            onTap!(index);
          } else {
            // Nếu không có onTap (như ở màn hình chi tiết), thì xử lý điều hướng
            if (index == currentIndex) {
              // Bấm lại tab hiện tại -> Quay về màn hình gốc của tab đó
              Navigator.popUntil(context, (route) => route.isFirst);
            } else {
              // Bấm tab khác -> Chuyển hướng sang MainScreen với tab mới
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MainScreen(initialIndex: index),
                ),
                (route) => false,
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Khám phá'),
          BottomNavigationBarItem(
            icon: Icon(Icons.near_me_outlined),
            label: 'Lân cận',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Chuyến đi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Đánh giá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
