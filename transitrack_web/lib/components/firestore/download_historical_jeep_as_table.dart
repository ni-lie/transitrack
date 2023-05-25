import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:transitrack_web/database_manager.dart';
import 'package:universal_html/html.dart' as html;

import '../../address_finder.dart';
import '../../config/route_coordinates.dart';


Future<void> downloadHistoricalJeepCollectionAsCSV(int routeId, Timestamp selectedDateTime) async {
  var historicalJeepDataList = await FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(routeId, selectedDateTime);

  Future<List<String>> getAddressFromLatLngList(List<dynamic> locations) async {
    List<Future<String>> addressFutures = locations.map((location) => getAddressFromLatLngFuture(location.latitude, location.longitude)).toList();
    return await Future.wait(addressFutures);
  }

  List<List<dynamic>> csvData1 = [
    ['Latest Jeep Data as of ${DateFormat('MM-dd-yyyy').format(selectedDateTime.toDate())}, Route: ${JeepRoutes[routeId].name}', ' ', ' ', ' ', ' '],
    ['Timestamp', 'Device ID', 'Passenger Count', 'Location', 'Street', 'Acceleration'], // Replace with your field names
    ...historicalJeepDataList.map((data) {
      return [
        DateFormat('MM-dd-yyyy-HH:mm:ss').format(data.timestamp.toDate()),
        data.device_id,
        data.passenger_count,
        '${data.location.latitude}, ${data.location.longitude}',
        '',
        data.acceleration,
      ];
    }),
  ];

  List<dynamic> locations = historicalJeepDataList.map((data) => data.location).toList();
  List<String> addresses = await getAddressFromLatLngList(locations);

  for (int i = 0; i < addresses.length; i++) {
    csvData1[i + 2][4] = addresses[i];
  }

  String csvContent = const ListToCsvConverter().convert(csvData1);
  
  String formattedDate = DateFormat('MM-dd-yyyy-HH-mm-ss').format(selectedDateTime.toDate());

  if(kIsWeb){
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement('a') as html.AnchorElement..href = url..style.display = 'none'..download = 'TransiTrack_historical_jeep_$formattedDate.csv';

    html.document.body!.children.add(anchor);

    anchor.click();

    html.Url.revokeObjectUrl(url);
  } else if (Platform.isAndroid){
    Directory generalDownloadDir = Directory('storage/emulated.0/Download');

    final File file = await (File('${generalDownloadDir.path}/TransiTrack_historical_jeep_$formattedDate.csv').create());

    await file.writeAsString(csvContent);
  }
}
