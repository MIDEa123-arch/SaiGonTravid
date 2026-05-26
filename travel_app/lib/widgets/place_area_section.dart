import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceAreaSection extends StatelessWidget {
  final PlaceDetail place;
  final double? distanceInKm;

  const PlaceAreaSection({super.key, required this.place, this.distanceInKm});

  String _getTransportationText() {
    if (distanceInKm == null) return 'Khoảng cách chưa được xác định';

    // Format distance with comma
    String distStr = distanceInKm!.toStringAsFixed(2).replaceAll('.', ',');

    if (distanceInKm! < 1.0) {
      return 'Đi bộ • $distStr km';
    } else if (distanceInKm! < 5.0) {
      return 'Xe máy / Ô tô • $distStr km';
    } else if (distanceInKm! < 20.0) {
      return 'Xe buýt / Ô tô • $distStr km';
    } else {
      return 'Xe khách / Tàu hoả / Máy bay • $distStr km';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (place.address == null || place.lat == null || place.lng == null) {
      return const SizedBox.shrink();
    }

    // Địa chỉ + Tên quận
    String addressLine = place.address!;
    if (place.district != null && place.district!.name.isNotEmpty) {
      addressLine += ' • ${place.district!.name}';
    }

    // Mã Plus Code (giả lập để hiển thị UI)
    String plusCodeStr = '';
    if (place.lat != null && place.lng != null) {
      plusCodeStr = _generateFakePlusCode(place.lat!, place.lng!);
      if (place.district != null && place.district!.name.isNotEmpty) {
        plusCodeStr += ' ${place.district!.name}, Hồ Chí Minh';
      }
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khu vực',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Địa chỉ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showAddressOptionsBottomSheet(context, addressLine),
            child: Text(
              addressLine,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plusCodeStr,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),

          const SizedBox(height: 16),

          const Text(
            'Phương thức đi lại',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getTransportationText(),
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),

          const SizedBox(height: 20),

          // Bản đồ Mini
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(place.lat!, place.lng!),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(place.lat!, place.lng!),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.yellow,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressOptionsBottomSheet(
    BuildContext context,
    String addressLine,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                const Text(
                  'Địa chỉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Option 1
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _launchGoogleMaps();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      'Nhận chỉ đường',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const Divider(
                  color: Colors.white24,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                // Option 2
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: addressLine));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép địa chỉ')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      'Sao chép địa chỉ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchGoogleMaps() async {
    if (place.lat != null && place.lng != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
      );
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          debugPrint('Could not launch Google Maps');
        }
      } catch (e) {
        debugPrint('Lỗi mở bản đồ: $e');
      }
    }
  }

  String _generateFakePlusCode(double lat, double lng) {
    const charset = "23456789CFGHJMPQRVWX";
    int hash = (lat.abs() * 10000 + lng.abs() * 10000).toInt();
    String code = "";
    for (int i = 0; i < 8; i++) {
      code += charset[hash % 20];
      hash ~/= 20;
    }
    String p1 = code.substring(0, 4);
    String p2 = code.substring(4, 8);
    String p3 = charset[hash % 20];
    String p4 = charset[(hash ~/ 20) % 20];
    return "$p1+$p2$p3$p4";
  }
}
