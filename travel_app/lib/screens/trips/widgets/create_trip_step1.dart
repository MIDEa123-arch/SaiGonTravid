import 'package:flutter/material.dart';

class Step1BasicInfoWidget extends StatelessWidget {
  final int numDays;
  final DateTime startDate;
  final Function(int) onDaysChanged;
  final Function(DateTime) onDateChanged;

  const Step1BasicInfoWidget({
    super.key, 
    required this.numDays, 
    required this.startDate, 
    required this.onDaysChanged, 
    required this.onDateChanged,
  });

  DateTime get _endDate => startDate.add(Duration(days: numDays - 1));

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        const Text("Thiết lập cơ bản", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        
        // 1. CHỌN SỐ NGÀY (Kéo dài Full Width)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Số ngày đi", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF222222), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF00D186), size: 28),
                    onPressed: () { if (numDays > 1) onDaysChanged(numDays - 1); },
                  ),
                  Text(
                    numDays.toString().padLeft(2, '0'), 
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00D186), size: 28),
                    onPressed: () => onDaysChanged(numDays + 1),
                  ),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 40),

        // 2. CHỌN LỊCH TRÌNH (Gọi Custom Calendar)
        const Text("Lịch trình dự kiến", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () async {
            // Mở Dialog Lịch Custom thay vì Lịch mặc định
            DateTime? picked = await showDialog<DateTime>(
              context: context,
              builder: (BuildContext context) {
                return CustomRangeCalendarDialog(
                  initialStartDate: startDate,
                  numDays: numDays,
                  primaryColor: const Color(0xFF00D186),
                );
              },
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF00D186).withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bắt đầu", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(_formatDate(startDate), style: const TextStyle(color: Color(0xFF00D186), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Kết thúc", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(_formatDate(_endDate), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// WIDGET LỊCH CUSTOM: TỰ ĐỘNG TÔ MÀU DẢI NGÀY
// =========================================================================
class CustomRangeCalendarDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final int numDays;
  final Color primaryColor;

  const CustomRangeCalendarDialog({
    super.key, 
    required this.initialStartDate, 
    required this.numDays,
    required this.primaryColor,
  });

  @override
  State<CustomRangeCalendarDialog> createState() => _CustomRangeCalendarDialogState();
}

class _CustomRangeCalendarDialogState extends State<CustomRangeCalendarDialog> {
  late DateTime _focusedMonth;
  late DateTime _selectedStartDate;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.initialStartDate;
    _focusedMonth = DateTime(_selectedStartDate.year, _selectedStartDate.month, 1);
  }

  DateTime get _selectedEndDate => _selectedStartDate.add(Duration(days: widget.numDays - 1));

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    // Tính khoảng trống đầu tháng (Chủ nhật = 0, Thứ 2 = 1,...)
    final firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7; 
    final totalCells = daysInMonth + firstDayOffset;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Tháng & Năm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  "Tháng ${_focusedMonth.month} - ${_focusedMonth.year}",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Dòng thứ (CN, T2,...)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
                  .map((e) => SizedBox(
                        width: 35,
                        child: Text(e, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),

            // Grid Lịch
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 2, // Khe hở dọc
                crossAxisSpacing: 0, // Dính liền ngang để highlight liền mạch
              ),
              itemBuilder: (context, index) {
                if (index < firstDayOffset) return const SizedBox(); // Ô trống đầu tháng

                final day = index - firstDayOffset + 1;
                final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                final now = DateTime.now();
                final isPast = currentDate.isBefore(DateTime(now.year, now.month, now.day));

                final isStart = _isSameDay(currentDate, _selectedStartDate);
                final isEnd = _isSameDay(currentDate, _selectedEndDate);
                final isInRange = currentDate.isAfter(_selectedStartDate) && currentDate.isBefore(_selectedEndDate);

                // Setup màu sắc & Bo góc
                Color bgColor = Colors.transparent;
                Color textColor = isPast ? Colors.grey[700]! : Colors.white;
                BorderRadius? borderRadius;

                if (isStart && isEnd) {
                  bgColor = widget.primaryColor;
                  textColor = Colors.black;
                  borderRadius = BorderRadius.circular(20);
                } else if (isStart) {
                  bgColor = widget.primaryColor;
                  textColor = Colors.black;
                  borderRadius = const BorderRadius.horizontal(left: Radius.circular(20)); // Bo góc trái
                } else if (isEnd) {
                  bgColor = widget.primaryColor;
                  textColor = Colors.black;
                  borderRadius = const BorderRadius.horizontal(right: Radius.circular(20)); // Bo góc phải
                } else if (isInRange) {
                  bgColor = widget.primaryColor.withOpacity(0.2); // Màu nhạt ở giữa
                  textColor = widget.primaryColor;
                }

                return GestureDetector(
                  onTap: isPast ? null : () {
                    setState(() {
                      _selectedStartDate = currentDate;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: borderRadius,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(color: textColor, fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Nút Xác nhận
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedStartDate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Xong", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}