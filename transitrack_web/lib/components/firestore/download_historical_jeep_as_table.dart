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

String getDirection(double angle) {
  // Define the directions and their corresponding angle ranges
  final directions = {
    'N': [67.5, 112.5],
    'NE': [22.5, 67.5],
    'E': [337.5, 22.5],
    'SE': [292.5, 337.5],
    'S': [247.5, 292.5],
    'SW': [202.5, 247.5],
    'W': [157.5, 202.5],
    'NW': [112.5, 157.5],
  };

  // Check which direction the angle falls into
  for (final entry in directions.entries) {
    final direction = entry.key;
    final angleRange = entry.value;
    if (angle >= angleRange[0] && angle < angleRange[1]) {
      return direction;
    } if ((angle >= 337.5 && angle <= 360) || (angle >= 0 && angle <= 22.5)) {
      return 'E';
    }
  }

  // If no direction is found, return an empty string
  return '';
}

Future<void> downloadHistoricalJeepCollectionAsCSV(int routeId, Timestamp selectedStartDateTime, Timestamp selectedEndDateTime) async {
  var historicalJeepDataList = await FireStoreDataBase().getLatestJeepDataPerDeviceIdFuturev2(routeId, selectedStartDateTime, selectedEndDateTime);

  Future<List<String>> getAddressFromLatLngList(List<dynamic> locations) async {
    List<Future<String>> addressFutures = locations.map((location) => getAddressFromLatLngFuture(location.latitude, location.longitude)).toList();
    return await Future.wait(addressFutures);
  }

  List<List<dynamic>> csvData1 = [
    ['Latest Jeep Data from ${DateFormat('MM-dd-yyyy-HH-mm-ss').format(selectedStartDateTime.toDate())} to ${DateFormat('MM-dd-yyyy-HH-mm-ss').format(selectedEndDateTime.toDate())}, Route: ${JeepRoutes[routeId].name}', ' ', ' ', ' ', ' '],
    ['Timestamp', 'Device ID', 'Passenger Count', 'Location', 'Street', 'Acceleration', 'Air quality', 'Gyroscope', 'Speed', 'Ambient Temperature', 'is_operating', 'bearing'],
    ...historicalJeepDataList.map((data) {
      return [
        DateFormat('MM-dd-yyyy-HH:mm:ss').format(data.timestamp.toDate()),
        data.device_id,
        data.passenger_count,
        '${data.location.latitude}, ${data.location.longitude}',
        '',
        data.acceleration,
        data.air_qual,
        data.gyroscope,
        data.speed,
        data.temp,
        data.is_active,
        "${data.bearing} (${getDirection(data.bearing)})",
      ];
    }),
  ];

  List<dynamic> locations = historicalJeepDataList.map((data) => data.location).toList();
  List<String> addresses = await getAddressFromLatLngList(locations);

  for (int i = 0; i < addresses.length; i++) {
    csvData1[i + 2][4] = addresses[i];
  }

  String csvContent = const ListToCsvConverter().convert(csvData1);

  if(kIsWeb){
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement('a') as html.AnchorElement..href = url..style.display = 'none'..download = 'TransiTrack_historical_jeep_${DateFormat('MM-dd-yyyy-HH-mm-ss').format(selectedStartDateTime.toDate())}_${DateFormat('MM-dd-yyyy-HH-mm-ss').format(selectedEndDateTime.toDate())}.csv';

    html.document.body!.children.add(anchor);

    anchor.click();

    html.Url.revokeObjectUrl(url);
  } else if (Platform.isAndroid){
    Directory generalDownloadDir = Directory('storage/emulated.0/Download');

    final File file = await (File('${generalDownloadDir.path}/TransiTrack_historical_jeep_${DateFormat('MM-dd-yyyy-HH-mm-ss').format(selectedStartDateTime.toDate())}_${DateFormat('MM-dd-yyyy-HH-mm-ss').format(selectedEndDateTime.toDate())}.csv').create());

    await file.writeAsString(csvContent);
  }
}
