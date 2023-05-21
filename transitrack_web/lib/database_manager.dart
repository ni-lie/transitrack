import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/heatmap_model.dart';
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

  Stream<List<HeatMapData>> fetchHeatMapRide(int route_id, Timestamp start, Timestamp end) {
    final Query<Map<String, dynamic>> heatmapRef = FirebaseFirestore.instance.collection('heatmap_ride').where('route_id', isEqualTo: route_id).where('timestamp', isGreaterThanOrEqualTo: start).where('timestamp', isLessThanOrEqualTo: end);
    return heatmapRef.snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return HeatMapData.fromSnapshot(doc);
      }).toList();
    });
  }

  Stream<List<HeatMapData>> fetchHeatMapDrop(int route_id, Timestamp start, Timestamp end) {
    final Query<Map<String, dynamic>> heatmapRef = FirebaseFirestore.instance.collection('heatmap_drop').where('route_id', isEqualTo: route_id).where('timestamp', isGreaterThanOrEqualTo: start).where('timestamp', isLessThanOrEqualTo: end);
    return heatmapRef.snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return HeatMapData.fromSnapshot(doc);
      }).toList();
    });
  }
}

