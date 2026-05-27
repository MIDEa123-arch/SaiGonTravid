import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/services.dart/api_service.dart';

class PopularTimesSection extends StatefulWidget {
  final int placeId;

  const PopularTimesSection({super.key, required this.placeId});

  @override
  State<PopularTimesSection> createState() => _PopularTimesSectionState();
}

class _PopularTimesSectionState extends State<PopularTimesSection> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 6 * 30.0);
  bool _isLoading = true;
  Map<String, dynamic>? _popularTimes;
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday, 6 = Sunday

  final List<String> _daysOfWeek = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPopularTimes();
  }

  Future<void> _loadPopularTimes() async {
    final data = await _api.getPopularTimes(widget.placeId);
    if (mounted) {
      setState(() {
        _popularTimes = data;
        _isLoading = false;
      });
    }
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDayIndex = (_selectedDayIndex + delta) % 7;
      if (_selectedDayIndex < 0) _selectedDayIndex += 7;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_popularTimes == null || _popularTimes!.isEmpty) {
      return const SizedBox.shrink();
    }

    bool hasData = false;
    for (var key in _popularTimes!.keys) {
      if ((_popularTimes![key] as List).isNotEmpty) {
        hasData = true;
        break;
      }
    }

    if (!hasData) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giờ đông khách',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<int>(
                color: AppColors.surface,
                offset: const Offset(0, 36),
                onSelected: (value) => setState(() => _selectedDayIndex = value),
                itemBuilder: (context) => List.generate(_daysOfWeek.length, (index) {
                  return PopupMenuItem(
                    value: index,
                    height: 36,
                    child: Text(_daysOfWeek[index], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  );
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _daysOfWeek[_selectedDayIndex],
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final dayData = _popularTimes![_selectedDayIndex.toString()] as List<dynamic>? ?? [];
    List<int> hourlyData = List.filled(24, 0);
    for (var item in dayData) {
      int hour = item['hour'];
      int percent = item['busy_percent'];
      if (hour >= 0 && hour < 24) {
        hourlyData[hour] = percent;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => _changeDay(-1),
          child: const Padding(
            padding: EdgeInsets.only(right: 2, bottom: 20),
            child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (index) {
              int percent = hourlyData[index];
              bool isLabelHour = [6, 9, 12, 15, 18, 21].contains(index);
              bool hasTick = index % 3 == 0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cột (Bar)
                    SizedBox(
                      height: 100,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: percent > 0
                            ? FractionallySizedBox(
                                heightFactor: percent / 100.0,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1.0), // Thu hẹp margin để bar mập mạp
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryEmerald,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(3),
                                      topRight: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    // Trục ngang liền mạch
                    Container(height: 1, color: Colors.white24, width: double.infinity),
                    // Dấu mọc (tick mark)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 1,
                        height: hasTick ? 5 : 2, // Dấu mọc dài cho giờ chẵn
                        color: Colors.white24,
                      ),
                    ),
                    // Label (06 giờ, 09 giờ...)
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 16,
                      child: isLabelHour
                          ? OverflowBox(
                              maxWidth: 40,
                              child: Text(
                                '${index.toString().padLeft(2, '0')} giờ',
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        GestureDetector(
          onTap: () => _changeDay(1),
          child: const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 20),
            child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}
