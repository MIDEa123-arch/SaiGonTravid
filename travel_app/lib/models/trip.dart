import 'package:travel_app/models/place.dart';

class TripPlace {
  final int itineraryId;
  final int dayIndex;
  final int orderIndex;
  final String? startTime;
  final Place place;

  TripPlace({
    required this.itineraryId,
    required this.dayIndex,
    required this.orderIndex,
    this.startTime,
    required this.place,
  });

  factory TripPlace.fromJson(Map<String, dynamic> json) {
    return TripPlace(
      itineraryId: json['itinerary_id'] ?? 0,
      dayIndex: json['day_index'] ?? 0,
      orderIndex: json['order_index'] ?? 0,
      startTime: json['start_time'],
      place: Place.fromJson(json['place']),
    );
  }
}

class Trip {
  final int tripId;
  final int userId;
  final String name;
  final DateTime startDate;
  final int numDays;
  final String? note;
  final String? coverImageUrl;
  final DateTime createdAt;
  final bool isCompleted;
  final List<TripPlace> itinerary;

  Trip({
    required this.tripId,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.numDays,
    this.note,
    this.coverImageUrl,
    required this.createdAt,
    required this.isCompleted,
    required this.itinerary,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    var list = json['itinerary'] as List? ?? [];
    List<TripPlace> itineraryList = list.map((i) => TripPlace.fromJson(i)).toList();

    return Trip(
      tripId: json['trip_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      numDays: json['num_days'] ?? 1,
      note: json['note'],
      coverImageUrl: json['cover_image_url'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isCompleted: json['is_completed'] ?? false,
      itinerary: itineraryList,
    );
  }
}
