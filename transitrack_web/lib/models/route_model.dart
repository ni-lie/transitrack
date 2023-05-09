import 'package:cloud_firestore/cloud_firestore.dart';

class RouteData{
  String device_id;
  int route_id;

  RouteData({
    required this.device_id,
    required this.route_id
  });

  factory RouteData.fromSnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    String device_id = data['device_id'];
    int route_id = data['route_id'];

    return RouteData(
      device_id: device_id,
      route_id: route_id
    );
  }
}