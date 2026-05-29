import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/screens/main_screen.dart';
import 'core/app_colors.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';
import 'package:travel_app/services.dart/auth_service.dart';
import 'package:travel_app/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đặt thanh điều hướng và trạng thái trong suốt (Edge-to-edge)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await FavoritePlacesService.loadFavorites();
  await AuthService.loadSession(); // Khôi phục session đăng nhập
  runApp(const MoodMapApp());
}

class MoodMapApp extends StatelessWidget {
  const MoodMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodMap',
      debugShowCheckedModeBanner: false,

      // THIẾT LẬP THEME (Màu sắc toàn cục)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Bật chế độ tối mặc định
        scaffoldBackgroundColor: AppColors.background, // Màu nền đen
        primaryColor: AppColors.primaryEmerald, // Màu xanh Emerald chủ đạo
        // Cấu hình font chữ đẹp (Inter) cho toàn App
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),

        // Hiệu ứng khi nhấn nút (Splash color)
        splashColor: AppColors.accentMint.withOpacity(0.2),
      ),

      // Màn hình đầu tiên hiện lên khi mở App
      home: const SplashScreen(), // Bắt đầu từ SplashScreen
    );
  }
}
