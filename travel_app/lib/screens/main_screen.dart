import 'package:flutter/material.dart';
import 'package:travel_app/screens/nearby/nearby_screen.dart';
import 'package:travel_app/screens/trips/trips_screen.dart';
import '../core/app_colors.dart';
import 'home/home_screen.dart';
import 'package:travel_app/widgets/shared_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }
  
  final List<Widget> _pages = [
    const HomeScreen(), // Tab: Khám phá
    const NearbyScreen(),
    const TripsScreen(),
    const Center(child: Text('Màn hình Đánh giá')),
    const Center(child: Text('Màn hình Tài khoản')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: SharedBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
