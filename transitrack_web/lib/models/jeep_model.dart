import 'package:cloud_firestore/cloud_firestore.dart';

class JeepData{
  String device_id;
  Timestamp timestamp;
  List<double> acceleration;
  int passenger_count;
  GeoPoint location;
  bool is_embark;

  JeepData({
    required this.device_id,
    required this.timestamp,
    required this.acceleration,
    required this.passenger_count,
    required this.location,
    required this.is_embark,
  });

  factory JeepData.fromSnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    String device_id = data['device_id'];
    Timestamp timestamp = data['timestamp'];
    List<double> acceleration = List.castFrom<dynamic, double>(data['acceleration']);
    int passenger_count = data['passenger_count'];
    GeoPoint location = data['location'];
    bool is_embark = data['is_embark'];

    return JeepData(
      device_id: device_id,
      timestamp: timestamp,
      acceleration: acceleration,
      passenger_count: passenger_count,
      location: location,
      is_embark: is_embark,
    );
  }
}