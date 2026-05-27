import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';

class ReviewFilterBottomSheet extends StatefulWidget {
  final int r5, r4, r3, r2, r1;
  final List<int> initialSelectedRatings;
  final String initialSelectedDate;
  final List<int> initialSelectedMonths;

  const ReviewFilterBottomSheet({
    super.key,
    required this.r5,
    required this.r4,
    required this.r3,
    required this.r2,
    required this.r1,
    this.initialSelectedRatings = const [],
    this.initialSelectedDate = 'Tất cả đánh giá',
    this.initialSelectedMonths = const [],
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required int r5,
    required int r4,
    required int r3,
    required int r2,
    required int r1,
    List<int> initialSelectedRatings = const [],
    String initialSelectedDate = 'Tất cả đánh giá',
    List<int> initialSelectedMonths = const [],
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewFilterBottomSheet(
        r5: r5,
        r4: r4,
        r3: r3,
        r2: r2,
        r1: r1,
        initialSelectedRatings: initialSelectedRatings,
        initialSelectedDate: initialSelectedDate,
        initialSelectedMonths: initialSelectedMonths,
      ),
    );
  }

  @override
  State<ReviewFilterBottomSheet> createState() =>
      _ReviewFilterBottomSheetState();
}

class _ReviewFilterBottomSheetState extends State<ReviewFilterBottomSheet> {
  late List<int> selectedRatings;
  late String selectedDate;
  late List<int> selectedMonths;

  @override
  void initState() {
    super.initState();
    selectedRatings = List.from(widget.initialSelectedRatings);
    selectedDate = widget.initialSelectedDate;
    selectedMonths = List.from(widget.initialSelectedMonths);
  }

  int _getCountForRating(int stars) {
    switch (stars) {
      case 5:
        return widget.r5;
      case 4:
        return widget.r4;
      case 3:
        return widget.r3;
      case 2:
        return widget.r2;
      case 1:
        return widget.r1;
      default:
        return 0;
    }
  }

  Widget _buildRatingOption(int stars) {
    int count = _getCountForRating(stars);
    bool hasReviews = count > 0;
    bool isSelected = selectedRatings.contains(stars);

    return GestureDetector(
      onTap: () {
        if (!hasReviews) return;
        setState(() {
          if (isSelected) {
            selectedRatings.remove(stars);
          } else {
            selectedRatings.add(stars);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : (hasReviews ? AppColors.primaryEmerald : Colors.white12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            bool isFilled = index < stars;
            return Container(
              margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? (hasReviews ? AppColors.primaryEmerald : Colors.white24)
                    : Colors.transparent,
                border: Border.all(
                  color: hasReviews ? AppColors.primaryEmerald : Colors.white24,
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDateOption(String text) {
    bool isSelected = selectedDate == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedDate = 'Tất cả đánh giá';
          } else {
            selectedDate = text;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.primaryEmerald,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthOption(String text, int monthValue) {
    bool isSelected = selectedMonths.contains(monthValue);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedMonths.remove(monthValue);
          } else {
            selectedMonths.add(monthValue);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // HIỆU ỨNG VIỀN TRẮNG KHI ĐƯỢC CHỌN (áp dụng cho cả tháng xem thêm)
            color: isSelected ? Colors.white : AppColors.primaryEmerald,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showAllMonthsPopup() async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: FractionallySizedBox(
            heightFactor: 1.0,
            child: _AllMonthsFilterWidget(initialSelected: selectedMonths),
          ),
        );
      },
    );

    // Lưu lại lựa chọn từ Popup tháng và cập nhật UI ở màn hình chính
    if (result != null) {
      setState(() {
        selectedMonths = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ lấy ra các tháng > 4 để gộp chung vào list hiển thị bên ngoài
    List<int> extraMonths = selectedMonths.where((m) => m > 4).toList();
    extraMonths.sort();

    return FractionallySizedBox(
      heightFactor: 1.0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Bộ lọc',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            toolbarHeight: 70,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Xếp hạng của khách du lịch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    _buildRatingOption(5),
                    _buildRatingOption(4),
                    _buildRatingOption(3),
                    _buildRatingOption(2),
                    _buildRatingOption(1),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ngày đánh giá',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    _buildDateOption('Tất cả đánh giá'),
                    _buildDateOption('3 tháng qua'),
                    _buildDateOption('6 tháng qua'),
                    _buildDateOption('12 tháng qua'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thời điểm trong năm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    for (int i = 1; i <= 4; i++)
                      _buildMonthOption('Tháng $i', i),
                    // NHỮNG THÁNG CHỌN TỪ POPUP (extraMonths) SẼ TỰ ĐỘNG HIỆN Ở ĐÂY & VIỀN TRẮNG
                    for (int m in extraMonths) _buildMonthOption('Tháng $m', m),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showAllMonthsPopup,
                  child: const Text(
                    'Xem thêm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRatings.clear();
                        selectedDate = 'Tất cả đánh giá';
                        selectedMonths.clear();
                      });
                    },
                    child: const Text(
                      'Xóa bộ lọc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'ratings': selectedRatings,
                        'date': selectedDate,
                        'months': selectedMonths,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Hiển thị đánh giá',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllMonthsFilterWidget extends StatefulWidget {
  final List<int> initialSelected;

  const _AllMonthsFilterWidget({required this.initialSelected});

  @override
  State<_AllMonthsFilterWidget> createState() => _AllMonthsFilterWidgetState();
}

class _AllMonthsFilterWidgetState extends State<_AllMonthsFilterWidget> {
  late List<int> selected;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    List<int> months = List.generate(12, (i) => i + 1);
    if (searchQuery.isNotEmpty) {
      months = months
          .where((m) => 'tháng $m'.contains(searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48), // Spacer để cân bằng với nút close
            const Text(
              'Thời điểm trong năm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context, selected),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white54),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tất cả các bộ lọc',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: months.length,
              itemBuilder: (context, index) {
                int m = months[index];
                bool isSel = selected.contains(m);
                return ListTile(
                  title: Text(
                    'Tháng $m',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSel) {
                          selected.remove(m);
                        } else {
                          selected.add(m);
                        }
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryEmerald
                            : Colors.transparent,
                        border: Border.all(
                          color: isSel
                              ? AppColors.primaryEmerald
                              : Colors.white24,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSel
                          ? const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (isSel) {
                        selected.remove(m);
                      } else {
                        selected.add(m);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      // BỔ SUNG XÓA BỘ LỌC + ÁP DỤNG Ở BOTTOM BAR GIỐNG MÀN HÌNH CHÍNH
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(top: BorderSide(color: Colors.white24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    selected.clear(); // Xóa tất cả các tháng đã chọn
                  });
                },
                child: const Text(
                  'Xóa bộ lọc',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    selected,
                  ); // Trả list kết quả về màn hình cũ
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
