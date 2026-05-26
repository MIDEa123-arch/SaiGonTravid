import 'package:flutter/material.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/screens/trips/widgets/create_trip_step1.dart';
import 'package:travel_app/screens/trips/widgets/create_trip_step2.dart';
import 'package:travel_app/screens/trips/widgets/create_trip_step3.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/services.dart/location_service.dart';
import 'package:geolocator/geolocator.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  int _currentStep = 0;

  // Data State
  int _numDays = 1;
  DateTime _startDate = DateTime.now();
  Map<int, List<Place>> _dayPlaces = {};

  final ApiService _apiService = ApiService();
  List<Place> _popularPlaces = [];
  bool _isLoading = true;

  // Step 3 State
  String? _currentAddress;
  double? _lat;
  double? _lng;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  Future<void> _loadApiData() async {
    try {
      final results = await _apiService.getExperiences();
      if (!mounted) return;
      setState(() {
        _popularPlaces = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLocation() async {
    try {
      Position position = await LocationService.getUserLocation(context);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _currentAddress =
            "${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}";
      });
    } catch (e) {
      print("Lỗi lấy vị trí: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF161616);
    const Color primaryColor = Color(0xFF00D186);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          "Tạo chuyến đi mới",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER CHUNG - Sửa logic hiển thị bước 1/3
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 3, // Chia cho 3 thay vì 4
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        primaryColor,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Bước ${_currentStep + 1}/3", // Đổi thành /3
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  StepIndicatorWidget(
                    currentStep: _currentStep,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _buildBodyForStep(),
            ),

            // NÚT ĐÁY - Logic dừng lại ở bước 2 (index của bước 3)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep == 1 && _lat == null) {
                      _refreshLocation();
                    }
                    if (_currentStep < 2) {
                      // Chỉ cho phép tăng tới index 2
                      setState(() => _currentStep++);
                    } else {
                      // Bước 4 cũ đã bị bỏ, đây là logic khi nhấn "Hoàn tất" ở bước 3
                      print("Lưu dữ liệu: ${_nameController.text}");
                      print("Số ngày: $_numDays");
                      print("Địa điểm: $_dayPlaces");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đang lưu chuyến đi...")),
                      );
                      // Logic Navigator.pop hoặc chuyển về Home ở đây
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2
                            ? "Hoàn tất"
                            : "Tiếp theo", // Sửa thành index 2
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 2
                            ? Icons.check
                            : Icons.arrow_forward, // Sửa thành index 2
                        color: Colors.black,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyForStep() {
    switch (_currentStep) {
      case 0:
        return Step1BasicInfoWidget(
          numDays: _numDays,
          startDate: _startDate,
          onDaysChanged: (val) => setState(() => _numDays = val),
          onDateChanged: (val) => setState(() => _startDate = val),
        );
      case 1:
        return Step2ItineraryWidget(
          numDays: _numDays,
          startDate: _startDate,
          dayPlaces: _dayPlaces,
          popularPlaces: _popularPlaces,
          onPlacesUpdated: (dayIndex, places) =>
              setState(() => _dayPlaces[dayIndex] = places),
        );
      case 2:
        return Step3ConfirmationWidget(
          currentAddress: _currentAddress,
          lat: _lat,
          lng: _lng,
          startDate: _startDate,
          numDays: _numDays,
          dayPlaces: _dayPlaces,
          nameController: _nameController,
          noteController: _noteController,
          onRefreshLocation: _refreshLocation,
        );
      default:
        return const SizedBox();
    }
  }
}

// =========================================================================
// WIDGET CHỈ BÁO - Sửa list steps còn 3 mục
// =========================================================================
class StepIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final Color primaryColor;

  const StepIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // Đã xóa "Generate"
    final steps = ["Chọn ngày", "Lịch trình", "Hoàn tất"];

    List<Widget> indicatorWidgets = [];

    for (int i = 0; i < steps.length; i++) {
      final isActive = i <= currentStep;

      indicatorWidgets.add(
        SizedBox(
          width: 80, // Tăng width một chút cho cân đối 3 bước
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isActive ? primaryColor : Colors.grey[700]!,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    "${i + 1}",
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[i],
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: isActive ? primaryColor : Colors.grey[600],
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );

      if (i < steps.length - 1) {
        indicatorWidgets.add(
          Expanded(
            child: Container(
              height: 1.5,
              color: isActive ? primaryColor : Colors.grey[800],
              margin: const EdgeInsets.only(top: 16),
            ),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: indicatorWidgets,
    );
  }
}
