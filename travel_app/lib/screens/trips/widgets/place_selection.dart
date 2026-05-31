import 'package:flutter/material.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/screens/main_screen.dart';
import 'package:travel_app/widgets/custom_image.dart';
import 'package:travel_app/core/app_colors.dart';

class PlaceSelectionScreen extends StatefulWidget {
  final List<Place> availablePlaces;
  final List<Place> initiallySelected;

  const PlaceSelectionScreen({super.key, required this.availablePlaces, required this.initiallySelected});

  @override
  State<PlaceSelectionScreen> createState() => _PlaceSelectionScreenState();
}

class _PlaceSelectionScreenState extends State<PlaceSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Place> _selectedPlaces = [];

  @override
  void initState() {
    super.initState();
    _selectedPlaces = List.from(widget.initiallySelected);
  }

  void _toggleSelection(Place place) {
    setState(() {
      if (_selectedPlaces.any((p) => p.id == place.id)) {
        _selectedPlaces.removeWhere((p) => p.id == place.id);
      } else {
        _selectedPlaces.add(place);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF161616);
    const Color primaryColor = Color(0xFF00D186); 

    List<Place> filteredList = widget.availablePlaces.where((p) => p.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text("Chọn địa điểm", style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),      
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF222222),
                  hintText: "Tìm trong danh sách đã lưu...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: widget.availablePlaces.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Chưa có địa điểm nào",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Bạn chưa lưu địa điểm nào cả. Hãy ra trang chủ và khám phá thêm các địa điểm thú vị nhé!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const MainScreen()),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text(
                                "Về trang chủ",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredList.isEmpty
                      ? Center(
                          child: Text("Không tìm thấy kết quả", style: TextStyle(color: Colors.grey[600])),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final place = filteredList[index];
                            final isSelected = _selectedPlaces.any((p) => p.id == place.id);
                  
                            return GestureDetector(
                              onTap: () => _toggleSelection(place),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? primaryColor : Colors.transparent,
                                        border: Border.all(color: isSelected ? primaryColor : Colors.grey),
                                      ),
                                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                                    ),
                                    const SizedBox(width: 15),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CustomImage(
                                        imageUrl: place.imageUrl,
                                        width: 65,
                                        height: 65,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place.name, 
                                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), 
                                            maxLines: 1, 
                                            overflow: TextOverflow.ellipsis
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${place.avgRating}",
                                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 4),
                                              Row(
                                                children: List.generate(5, (dotIndex) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(right: 2),
                                                    child: Icon(
                                                      Icons.circle,
                                                      size: 10,
                                                      color: (place.avgRating > dotIndex)
                                                          ? AppColors.primaryEmerald
                                                          : Colors.grey.withOpacity(0.3),
                                                    ),
                                                  );
                                                }),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "(${(place.totalReviews).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})",
                                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  place.address ?? 'Đang cập nhật', 
                                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (place.priceRange != null && place.priceRange!.trim().isNotEmpty) ...[
                                                Text(" • ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                                Text(
                                                  place.priceRange!,
                                                  style: TextStyle(color: Colors.blue[300], fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedPlaces), 
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text("Lưu (${_selectedPlaces.length} địa điểm)", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}