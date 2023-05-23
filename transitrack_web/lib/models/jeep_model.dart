import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class JeepData{
  String device_id;
  Timestamp timestamp;
  List<double> acceleration;
  double speed;
  int passenger_count;
  GeoPoint location;
  bool is_active;
  int route_id;
  bool embark;
  bool disembark;
  List<double> gyroscope;
  double temp;
  int air_qual;

  JeepData({
    required this.device_id,
    required this.timestamp,
    required this.acceleration,
    required this.speed,
    required this.passenger_count,
    required this.location,
    required this.is_active,
    required this.route_id,
    required this.embark,
    required this.disembark,
    required this.gyroscope,
    required this.temp,
    required this.air_qual
  });

  factory JeepData.fromSnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    String device_id = data['device_id'];
    Timestamp timestamp  = data['timestamp'];
    List<double> acceleration = List.castFrom<dynamic, double>(data['acceleration']);
    double speed = data['speed'] as double;
    int passenger_count = data['passenger_count'];
    GeoPoint location = data['location'];
    bool is_active = data['is_active'];
    int route_id = data['route_id'];
    bool embark = data['embark'] as bool;
    bool disembark = data['disembark'] as bool;
    List<double> gyroscope = List.castFrom<dynamic, double>(data['gyroscope']);
    double temp = data['temp'] as double;
    int air_qual = data['air_qual'];

    return JeepData(
      device_id: device_id,
      timestamp: timestamp,
      acceleration: acceleration,
      speed: speed,
      passenger_count: passenger_count,
      location: location,
      is_active: is_active,
      route_id: route_id,
      embark: embark,
      disembark: disembark,
      gyroscope: gyroscope,
      temp: temp,
      air_qual: air_qual
    );
  }
}

class JeepEntity{
  JeepData jeep;
  Symbol data;

  JeepEntity({
   required this.jeep,
   required this.data
  });
}