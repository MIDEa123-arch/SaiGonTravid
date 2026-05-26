import 'package:flutter/material.dart';
import 'package:travel_app/models/place.dart';

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
              child: ListView.builder(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(place.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(place.address ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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