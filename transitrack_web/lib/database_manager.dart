import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/jeep_model.dart';
import 'models/route_model.dart';

class FireStoreDataBase{
  List<RouteData> routeList = [];
  List<JeepData> jeepList = [];

  // Future getData() async {
  //   try{
  //     await jeepRef.get().then((querySnapshot) {
  //       for (var doc in querySnapshot.docs) {
  //         JeepData jeepData = JeepData.fromSnapshot(doc);
  //         jeepList.add(jeepData);
  //       }
  //     });
  //     return jeepList;
  //   }catch(e){
  //     debugPrint("Error - $e");
  //     return null;
  //   }
  // }

  Stream<List<RouteData>> fetchRouteData(int route_id) {
    final Query<Map<String, dynamic>> routeRef = FirebaseFirestore.instance.collection('routes').where('route_id', isEqualTo: route_id);

    return routeRef.snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return RouteData.fromSnapshot(doc);
      }).toList();
    });
  }

  Stream<List<JeepData>> fetchJeepData(List<String> device_list) {
    final Query<Map<String, dynamic>> jeepRef = FirebaseFirestore.instance.collection('jeeps').where('device_id', whereIn: device_list).where('is_embark', isEqualTo: true);
    return jeepRef.snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return JeepData.fromSnapshot(doc);
      }).toList();
    });
  }

  Stream<Stream<List<JeepData>>> getJeepsForRoute(int routeChoice) {
    return FirebaseFirestore.instance.collection('routes').where('route_id', isEqualTo: routeChoice).snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      final List<RouteData> deviceIds = querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        return RouteData.fromSnapshot(doc);
      }).toList();
      List<String> devices = [];
      for (var i = 0; i < deviceIds.length; i++) {devices.add(deviceIds[i].device_id);}
      final Query<Map<String, dynamic>> jeepRef = FirebaseFirestore.instance.collection('jeeps').where('device_id', whereIn: devices).where('is_embark', isEqualTo: true);
      return jeepRef.snapshots().map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
        return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return JeepData.fromSnapshot(doc);
        }).toList();
      });
    });
  }
}