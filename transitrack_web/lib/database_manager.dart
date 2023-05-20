import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/heatmap_ride_model.dart';
import 'models/jeep_model.dart';

class FireStoreDataBase{
  Stream<List<JeepData>> fetchJeepData(int route_id) {
    final Query<Map<String, dynamic>> jeepRef = FirebaseFirestore.instance.collection('jeeps').where('route_id', isEqualTo: route_id);
    return jeepRef.snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return JeepData.fromSnapshot(doc);
      }).toList();
    });
  }

  Stream<List<HeatMapRideData>> fetchHeatMapRide(int route_id) {
    final Query<Map<String, dynamic>> heatmapRef = FirebaseFirestore.instance.collection('heatmap_ride').where('route_id', isEqualTo: route_id);
    return heatmapRef.snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return HeatMapRideData.fromSnapshot(doc);
      }).toList();
    });
  }

  Future<List<JeepData>> loadJeepsByRouteId(int routeId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('jeeps')
        .where('route_id', isEqualTo: routeId)
        .get();

    List<JeepData> jeepDataList = snapshot.docs
        .map((doc) => JeepData.fromSnapshot(doc))
        .toList();

    return jeepDataList;
  }

  Future<List<HeatMapRideData>> loadHeatMapRide(int routeId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('heatmap_ride')
        .where('route_id', isEqualTo: routeId)
        .get();

    List<HeatMapRideData> heatmapData = snapshot.docs
        .map((doc) => HeatMapRideData.fromSnapshot(doc))
        .toList();

    return heatmapData;
  }
}

