import 'package:flutter/material.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/screens/trips/widgets/create_trip_step1.dart';
import 'package:travel_app/screens/trips/widgets/create_trip_step2.dart';
import 'package:travel_app/screens/trips/widgets/create_trip_step3.dart';
import 'package:travel_app/screens/trips/widgets/create_trip_step3_time.dart';
import 'package:travel_app/widgets/top_toast.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/services.dart/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_app/services.dart/auth_service.dart';

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
  Map<String, String> _placeTimes = {}; // key: "${dayIndex}_${place.id}"

  final ApiService _apiService = ApiService();
  List<Place> _savedPlaces = [];
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
      final user = AuthService.currentUserNotifier.value;
      if (user != null) {
        final results = await _apiService.getSavedPlaces(user.userId);
        if (!mounted) return;
        setState(() {
          _savedPlaces = results;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
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
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
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
                      value: (_currentStep + 1) / 4, 
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        primaryColor,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Bước ${_currentStep + 1}/4", 
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
                    if (_currentStep == 1) {
                      if (_lat == null) {
                        _refreshLocation();
                      }
                      bool hasPlaces = _dayPlaces.values.any((list) => list.isNotEmpty);
                      if (!hasPlaces) {
                        TopToast.show(context, "Vui lòng thêm ít nhất một địa điểm vào lịch trình!", isError: true);
                        return;
                      }
                    }

                    if (_currentStep == 2) {
                      bool valid = true;
                      for (var entry in _dayPlaces.entries) {
                        final dayIndex = entry.key;
                        final placesList = entry.value;
                        Set<String> selectedTimes = {};

                        for (var place in placesList) {
                          final timeKey = "${dayIndex}_${place.id}";
                          final timeValue = _placeTimes[timeKey];
                          if (timeValue == null) {
                            valid = false;
                            TopToast.show(context, "Vui lòng chọn thời gian cho tất cả địa điểm", isError: true);
                            return;
                          }
                          if (selectedTimes.contains(timeValue)) {
                            valid = false;
                            TopToast.show(context, "Lỗi trùng lặp thời gian ở Ngày ${dayIndex + 1}", isError: true);
                            return;
                          }
                          selectedTimes.add(timeValue);
                        }
                      }
                      if (!valid) return;
                    }

                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                    } else {
                      if (_nameController.text.trim().isEmpty) {
                        TopToast.show(context, "Vui lòng nhập tên chuyến đi", isError: true);
                        return;
                      }

                      TopToast.show(context, "Đang lưu chuyến đi...", isError: false);

                      List<Map<String, dynamic>> places = [];
                      _dayPlaces.forEach((day, placeList) {
                        for (int i = 0; i < placeList.length; i++) {
                          final timeKey = "${day}_${placeList[i].id}";
                          places.add({
                            "day_index": day,
                            "place_id": placeList[i].id,
                            "order_index": i,
                            "start_time": _placeTimes[timeKey],
                          });
                        }
                      });

                      final tripData = {
                        "name": _nameController.text.trim(),
                        "start_date": _startDate.toIso8601String(),
                        "num_days": _numDays,
                        "note": _noteController.text.trim(),
                        "places": places,
                      };

                      final user = AuthService.currentUserNotifier.value;
                      if (user != null) {
                        _apiService.createTrip(tripData, user.userId).then((
                          trip,
                        ) {
                          if (trip != null) {
                            TopToast.show(context, "Tạo chuyến đi thành công!", isError: false);
                            Navigator.pop(context); // Trở về màn hình trước
                          } else {
                            TopToast.show(context, "Lỗi tạo chuyến đi", isError: true);
                          }
                        });
                      } else {
                        TopToast.show(context, "Vui lòng đăng nhập", isError: true);
                      }
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
                        _currentStep == 3
                            ? "Hoàn tất"
                            : "Tiếp theo", 
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 3
                            ? Icons.check
                            : Icons.arrow_forward, 
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
          popularPlaces: _savedPlaces,
          onPlacesUpdated: (dayIndex, places) =>
              setState(() => _dayPlaces[dayIndex] = places),
        );
      case 2:
        return Step3TimeSelectionWidget(
          numDays: _numDays,
          startDate: _startDate,
          dayPlaces: _dayPlaces,
          placeTimes: _placeTimes,
          onTimeSelected: (dayIndex, placeId, time) {
            setState(() {
              _placeTimes["${dayIndex}_${placeId}"] = time;
            });
          },
        );
      case 3:
        return Step3ConfirmationWidget(
          currentAddress: _currentAddress,
          lat: _lat,
          lng: _lng,
          startDate: _startDate,
          numDays: _numDays,
          dayPlaces: _dayPlaces,
          placeTimes: _placeTimes,
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

  Widget build(BuildContext context) {
    final steps = ["Chọn ngày", "Lịch trình", "Chọn giờ", "Hoàn tất"];

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
